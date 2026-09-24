// Ekstraksi vektor biometrik wajah — 100% di sisi server.
// Tidak bergantung pada sensor/kunci layar perangkat. Input: foto selfie JPEG
// (data URL) dari kamera depan; output: vektor ternormalisasi (L2) yang
// disimpan di database dan dicocokkan server-side dengan cosine similarity.
import jpeg from "jpeg-js";

export const FACE_DIM = 192;
/** Ambang bawaan kecocokan wajah (dapat diubah Super Admin lewat pengaturan). */
export const FACE_MATCH_THRESHOLD = 0.78;
/** Selisih di atas ambang agar template diperbarui bertahap (EMA). */
export const FACE_ADAPT_MARGIN = 0.1;
/** Rentang ambang yang boleh diatur. */
export const FACE_THRESHOLD_MIN = 0.6;
export const FACE_THRESHOLD_MAX = 0.95;
/** Toleransi fusi kontekstual (GPS kantor + perangkat tepercaya). */
export const FACE_FUSION_MARGIN = 0.04;
/** Skor keaslian minimal (selisih kecerahan saat layar berkedip). */
export const LIVENESS_MIN = 1.5;
/** Bobot sampel baru saat penyesuaian bertahap. */
export const FACE_ADAPT_ALPHA = 0.1;

export function decodeDataUrl(dataUrl: string): { mime: string; bin: Buffer } {
  const m = /^data:(image\/[a-z+]+);base64,(.+)$/i.exec(dataUrl.trim());
  if (!m) throw new Error("Format foto tidak valid");
  return { mime: m[1].toLowerCase(), bin: Buffer.from(m[2], "base64") };
}

/** Grayscale 64x64 hasil center-crop, dinormalisasi terhadap pencahayaan. */
function toGray64(bin: Buffer): Float64Array {
  const img = jpeg.decode(bin, { useTArray: true, formatAsRGBA: true });
  const { width: W, height: H, data } = img;
  const side = Math.min(W, H);
  const ox = Math.floor((W - side) / 2);
  const oy = Math.floor((H - side) / 2);
  const N = 64;
  const g = new Float64Array(N * N);
  for (let y = 0; y < N; y++) {
    const sy = oy + Math.floor((y + 0.5) * (side / N));
    for (let x = 0; x < N; x++) {
      const sx = ox + Math.floor((x + 0.5) * (side / N));
      const i = (sy * W + sx) * 4;
      g[y * N + x] = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
    }
  }
  let mean = 0;
  for (let i = 0; i < g.length; i++) mean += g[i];
  mean /= g.length;
  let varSum = 0;
  for (let i = 0; i < g.length; i++) varSum += (g[i] - mean) ** 2;
  const std = Math.sqrt(varSum / g.length) || 1;
  for (let i = 0; i < g.length; i++) g[i] = (g[i] - mean) / std;
  return g;
}

/** Skor kualitas kasar 0–100 (kontras & ketajaman). */
export function imageQuality(dataUrl: string): number {
  const { bin } = decodeDataUrl(dataUrl);
  const img = jpeg.decode(bin, { useTArray: true, formatAsRGBA: true });
  const { width: W, height: H, data } = img;
  let sum = 0;
  let sum2 = 0;
  let n = 0;
  for (let i = 0; i < data.length; i += 16) {
    const v = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
    sum += v;
    sum2 += v * v;
    n++;
  }
  const mean = sum / n;
  const std = Math.sqrt(Math.max(0, sum2 / n - mean * mean));
  const resScore = Math.min(1, Math.min(W, H) / 320);
  const contrast = Math.min(1, std / 55);
  const exposure = 1 - Math.min(1, Math.abs(mean - 128) / 128);
  return Math.round(100 * (0.4 * contrast + 0.35 * exposure + 0.25 * resScore));
}

/**
 * Normalisasi kontras lokal (mirip CLAHE ringan): tiap piksel dinormalisasi
 * terhadap rata-rata & simpangan jendela 9x9 di sekitarnya. Menetralkan
 * bayangan samping dan perbedaan pencahayaan ruangan.
 */
function localContrastNormalize(g: Float64Array, N: number, r = 4): Float64Array {
  const W = N + 1;
  const S = new Float64Array(W * W);
  const S2 = new Float64Array(W * W);
  for (let y = 0; y < N; y++) {
    let row = 0;
    let row2 = 0;
    for (let x = 0; x < N; x++) {
      const v = g[y * N + x];
      row += v;
      row2 += v * v;
      S[(y + 1) * W + x + 1] = S[y * W + x + 1] + row;
      S2[(y + 1) * W + x + 1] = S2[y * W + x + 1] + row2;
    }
  }
  const out = new Float64Array(N * N);
  for (let y = 0; y < N; y++) {
    const y0 = Math.max(0, y - r);
    const y1 = Math.min(N, y + r + 1);
    for (let x = 0; x < N; x++) {
      const x0 = Math.max(0, x - r);
      const x1 = Math.min(N, x + r + 1);
      const n = (y1 - y0) * (x1 - x0);
      const sum = S[y1 * W + x1] - S[y0 * W + x1] - S[y1 * W + x0] + S[y0 * W + x0];
      const sum2 = S2[y1 * W + x1] - S2[y0 * W + x1] - S2[y1 * W + x0] + S2[y0 * W + x0];
      const mean = sum / n;
      const std = Math.sqrt(Math.max(0, sum2 / n - mean * mean));
      out[y * N + x] = (g[y * N + x] - mean) / (std + 0.35);
    }
  }
  return out;
}

/**
 * Bobot area wajah: gaussian eliptis berpusat di area mata–hidung–mulut.
 * Tepi (rambut, hijab, peci, kerah) mendapat bobot kecil karena sering berubah.
 */
function interiorWeight(nx: number, ny: number): number {
  const dx = (nx - 0.5) / 0.3;
  const dy = (ny - 0.54) / 0.36;
  return Math.max(0.15, Math.exp(-0.5 * (dx * dx + dy * dy)));
}

/** Vektor biometrik wajah 192 dimensi (blok intensitas + histogram gradien). */
export function extractFaceEmbedding(dataUrl: string): number[] {
  const { mime, bin } = decodeDataUrl(dataUrl);
  if (!/jpe?g/.test(mime)) throw new Error("Foto harus berformat JPEG");
  if (bin.byteLength > 2_500_000) throw new Error("Ukuran foto maksimal 2.5 MB");
  const N = 64;
  const g = localContrastNormalize(toGray64(bin), N);
  const v: number[] = [];

  // (a) 64 dimensi: rata-rata intensitas blok 8x8, dibobot area wajah
  for (let by = 0; by < 8; by++) {
    for (let bx = 0; bx < 8; bx++) {
      let s = 0;
      for (let y = 0; y < 8; y++)
        for (let x = 0; x < 8; x++) s += g[(by * 8 + y) * N + (bx * 8 + x)];
      v.push((s / 64) * interiorWeight((bx + 0.5) / 8, (by + 0.5) / 8));
    }
  }

  // (b) 128 dimensi: histogram orientasi gradien (8 bin) grid 4x4, dibobot area wajah
  const bins = 8;
  for (let cy = 0; cy < 4; cy++) {
    for (let cx = 0; cx < 4; cx++) {
      const hist = new Array<number>(bins).fill(0);
      for (let y = 1; y < 15; y++) {
        for (let x = 1; x < 15; x++) {
          const py = cy * 16 + y;
          const px = cx * 16 + x;
          const gx = g[py * N + px + 1] - g[py * N + px - 1];
          const gy = g[(py + 1) * N + px] - g[(py - 1) * N + px];
          const mag = Math.hypot(gx, gy);
          let ang = Math.atan2(gy, gx);
          if (ang < 0) ang += Math.PI * 2;
          const b = Math.min(bins - 1, Math.floor((ang / (Math.PI * 2)) * bins));
          hist[b] += mag;
        }
      }
      const norm = Math.hypot(...hist) || 1;
      const w = interiorWeight((cx + 0.5) / 4, (cy + 0.5) / 4);
      for (const h of hist) v.push((h / norm) * w);
    }
  }

  return l2normalize(v);
}

export function l2normalize(v: number[]): number[] {
  let s = 0;
  for (const x of v) s += x * x;
  const n = Math.sqrt(s) || 1;
  return v.map((x) => x / n);
}

export function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length) return 0;
  let dot = 0;
  for (let i = 0; i < a.length; i++) dot += a[i] * b[i];
  return dot;
}

/** Rata-rata beberapa sampel wajah menjadi satu template. */
export function averageEmbeddings(list: number[][]): number[] {
  const out = new Array<number>(list[0].length).fill(0);
  for (const v of list) for (let i = 0; i < v.length; i++) out[i] += v[i];
  return l2normalize(out.map((x) => x / list.length));
}

/** Penyesuaian bertahap: V_baru = (1-α)·V_lama + α·V_hari_ini */
export function adaptEmbedding(oldV: number[], fresh: number[], alpha = FACE_ADAPT_ALPHA): number[] {
  return l2normalize(oldV.map((x, i) => (1 - alpha) * x + alpha * fresh[i]));
}

// Pemotongan & standarisasi area wajah di sisi peramban (browser-only).
// Tujuan: menghilangkan latar belakang dan menyamakan skala wajah, agar vektor
// biometrik yang dihitung di server konsisten antara saat perekaman admin dan
// saat absensi harian ASN.
//
// Strategi:
//  1. Bila peramban mendukung FaceDetector (Chrome/Android), gunakan kotak wajah
//     hasil deteksi lalu diperluas dengan margin tetap.
//  2. Bila tidak didukung, gunakan area bingkai oval pemandu di layar sebagai
//     kotak potong. Karena ASN diminta mengisi bingkai, hasilnya tetap seragam.
// Hasil selalu berupa JPEG persegi FACE_CROP_SIZE x FACE_CROP_SIZE.

export const FACE_CROP_SIZE = 256;
/** Proporsi tinggi bingkai oval pemandu terhadap tinggi frame kamera. */
const GUIDE_HEIGHT_RATIO = 0.78;
/** Margin di sekitar kotak wajah hasil deteksi (kali lebar/tinggi kotak). */
const DETECT_MARGIN = 0.35;

export type FaceBox = { x: number; y: number; width: number; height: number };

type NativeDetector = {
  detect: (src: CanvasImageSource) => Promise<Array<{ boundingBox: FaceBox }>>;
};

let detector: NativeDetector | null | undefined;

function getDetector(): NativeDetector | null {
  if (detector !== undefined) return detector;
  const Ctor = (globalThis as unknown as { FaceDetector?: new (o?: unknown) => NativeDetector })
    .FaceDetector;
  detector = Ctor ? new Ctor({ fastMode: true, maxDetectedFaces: 1 }) : null;
  return detector;
}

export function faceDetectionSupported(): boolean {
  return getDetector() !== null;
}

/** Kotak potong cadangan: area bingkai oval pemandu di tengah frame. */
export function guideBox(w: number, h: number): FaceBox {
  const side = Math.min(h * GUIDE_HEIGHT_RATIO, w * 0.92);
  return { x: (w - side) / 2, y: (h - side) / 2, width: side, height: side };
}

/** Deteksi kotak wajah pada sumber gambar; null bila tidak ada/ tidak didukung. */
export async function detectFaceBox(src: CanvasImageSource): Promise<FaceBox | null> {
  const d = getDetector();
  if (!d) return null;
  try {
    const faces = await d.detect(src);
    const f = faces?.[0];
    if (!f?.boundingBox) return null;
    const b = f.boundingBox;
    return { x: b.x, y: b.y, width: b.width, height: b.height };
  } catch {
    return null;
  }
}

function expand(box: FaceBox, w: number, h: number): FaceBox {
  const side = Math.max(box.width, box.height) * (1 + DETECT_MARGIN * 2);
  const cx = box.x + box.width / 2;
  const cy = box.y + box.height / 2;
  const s = Math.min(side, w, h);
  return {
    x: Math.min(Math.max(0, cx - s / 2), w - s),
    y: Math.min(Math.max(0, cy - s / 2), h - s),
    width: s,
    height: s,
  };
}

/**
 * Ambil satu frame dari kamera, potong ke area wajah, dan kembalikan JPEG
 * persegi berukuran seragam (data URL).
 */
export async function captureFaceCrop(
  video: HTMLVideoElement,
  quality = 0.85,
): Promise<{ dataUrl: string; detected: boolean } | null> {
  const vw = video.videoWidth;
  const vh = video.videoHeight;
  if (!vw || !vh) return null;

  // Frame penuh dulu, supaya deteksi bekerja pada gambar diam (stabil).
  const frame = document.createElement("canvas");
  frame.width = vw;
  frame.height = vh;
  const fctx = frame.getContext("2d");
  if (!fctx) return null;
  fctx.drawImage(video, 0, 0, vw, vh);

  const found = await detectFaceBox(frame);
  const box = found ? expand(found, vw, vh) : guideBox(vw, vh);

  const out = document.createElement("canvas");
  out.width = FACE_CROP_SIZE;
  out.height = FACE_CROP_SIZE;
  const ctx = out.getContext("2d");
  if (!ctx) return null;
  ctx.drawImage(
    frame,
    box.x,
    box.y,
    box.width,
    box.height,
    0,
    0,
    FACE_CROP_SIZE,
    FACE_CROP_SIZE,
  );
  return { dataUrl: out.toDataURL("image/jpeg", quality), detected: !!found };
}

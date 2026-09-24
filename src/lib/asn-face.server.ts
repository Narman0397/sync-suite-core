// Helper server-only untuk biometrik wajah terpusat & retensi foto absensi.
import {
  adaptEmbedding,
  averageEmbeddings,
  cosineSimilarity,
  extractFaceEmbedding,
  imageQuality,
  FACE_DIM,
  FACE_ADAPT_MARGIN,
  FACE_MATCH_THRESHOLD,
  FACE_THRESHOLD_MAX,
  FACE_THRESHOLD_MIN,
} from "@/lib/face-embedding.server";

export const MIN_FACE_SAMPLES = 3;
export const FOTO_RETENTION_DAYS = 7;
export const FACE_THRESHOLD_KEY = "face_match_threshold";

export type FaceTemplate = {
  id: string;
  user_id: string;
  embedding: number[];
  samples: number;
  quality: number | null;
  adapt_count: number;
  updated_at: string;
  aktif: boolean;
};

/**
 * Multi-template disimpan dalam satu kolom vektor: [rata-rata, pose1, pose2, pose3]
 * (masing-masing FACE_DIM). Template format lama (hanya 1 vektor) dianggap usang.
 */
function unpack(v: number[]): { avg: number[]; poses: number[][] } | null {
  if (!Array.isArray(v) || v.length < FACE_DIM * 2 || v.length % FACE_DIM !== 0) return null;
  const parts: number[][] = [];
  for (let i = 0; i < v.length; i += FACE_DIM) parts.push(v.slice(i, i + FACE_DIM).map(Number));
  return { avg: parts[0], poses: parts.slice(1) };
}
function pack(avg: number[], poses: number[][]): number[] {
  return [...avg, ...poses.flat()];
}

export function clampThreshold(t: number) {
  return Math.min(FACE_THRESHOLD_MAX, Math.max(FACE_THRESHOLD_MIN, Number(t.toFixed(2))));
}

export async function getFaceThreshold(): Promise<number> {
  const { data } = await supabaseAdmin
    .from("app_setting")
    .select("value")
    .eq("key", FACE_THRESHOLD_KEY)
    .maybeSingle();
  const t = Number((data?.value as { threshold?: unknown } | null)?.threshold);
  return Number.isFinite(t) ? clampThreshold(t) : FACE_MATCH_THRESHOLD;
}

export async function setFaceThreshold(t: number) {
  const value = clampThreshold(t);
  const { error } = await supabaseAdmin
    .from("app_setting")
    .upsert(
      { key: FACE_THRESHOLD_KEY, value: { threshold: value }, public_visible: false },
      { onConflict: "key" },
    );
  if (error) throw new Error(error.message);
  return value;
}

export async function getFaceTemplate(userId: string): Promise<FaceTemplate | null> {
  const { data } = await supabaseAdmin
    .from("asn_face_template")
    .select("id,user_id,embedding,samples,quality,adapt_count,updated_at,aktif")
    .eq("user_id", userId)
    .maybeSingle();
  if (!data || !data.aktif) return null;
  return data as unknown as FaceTemplate;
}

/** Admin merekam wajah ASN: minimal 3 sampel (depan, serong kiri, serong kanan). */
export async function enrollFace(opts: {
  userId: string;
  opdId: string | null;
  photos: string[];
  enrolledBy: string;
}) {
  if (opts.photos.length < MIN_FACE_SAMPLES)
    throw new Error(`Minimal ${MIN_FACE_SAMPLES} foto wajah diperlukan.`);
  const qualities = opts.photos.map((p) => imageQuality(p));
  const worst = Math.min(...qualities);
  if (worst < 35)
    throw new Error("Kualitas foto terlalu rendah. Pastikan pencahayaan cukup dan wajah jelas.");
  const vectors = opts.photos.map((p) => extractFaceEmbedding(p));
  for (let i = 1; i < vectors.length; i++) {
    if (cosineSimilarity(vectors[0], vectors[i]) < 0.55)
      throw new Error("Sampel wajah tidak konsisten. Ulangi perekaman dengan latar yang sama.");
  }
  const embedding = pack(averageEmbeddings(vectors), vectors);
  const avgQuality = Math.round(qualities.reduce((a, b) => a + b, 0) / qualities.length);
  const { error } = await supabaseAdmin.from("asn_face_template").upsert(
    {
      user_id: opts.userId,
      opd_id: opts.opdId,
      embedding,
      samples: opts.photos.length,
      quality: avgQuality,
      adapt_count: 0,
      aktif: true,
      enrolled_by: opts.enrolledBy,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id" },
  );
  if (error) throw new Error(error.message);
  return { ok: true, quality: avgQuality, samples: opts.photos.length };
}

/**
 * Cocokkan selfie dengan template multi-pose: skor = kemiripan tertinggi
 * terhadap rata-rata atau salah satu pose. Bila sangat yakin, rata-rata dan
 * pose terdekat diperbarui bertahap (EMA 0.90/0.10).
 */
export async function verifyFace(userId: string, photo: string) {
  const threshold = await getFaceThreshold();
  const tpl = await getFaceTemplate(userId);
  if (!tpl)
    return { enrolled: false, verified: false, score: null as number | null, threshold, outdated: false };
  const t = unpack(tpl.embedding);
  if (!t) return { enrolled: true, verified: false, score: 0, threshold, outdated: true };
  const fresh = extractFaceEmbedding(photo);
  const avgScore = cosineSimilarity(t.avg, fresh);
  let best = -1;
  let bestScore = -1;
  t.poses.forEach((p, i) => {
    const sc = cosineSimilarity(p, fresh);
    if (sc > bestScore) {
      bestScore = sc;
      best = i;
    }
  });
  const score = Math.max(avgScore, bestScore);
  const verified = score >= threshold;
  if (verified && score >= Math.min(0.98, threshold + FACE_ADAPT_MARGIN)) {
    const poses = t.poses.map((p, i) => (i === best ? adaptEmbedding(p, fresh) : p));
    await supabaseAdmin
      .from("asn_face_template")
      .update({
        embedding: pack(adaptEmbedding(t.avg, fresh), poses),
        adapt_count: tpl.adapt_count + 1,
        updated_at: new Date().toISOString(),
      })
      .eq("id", tpl.id);
  }
  return { enrolled: true, verified, score: Number(score.toFixed(4)), threshold, outdated: false };
}

/** Apakah ASN punya penugasan WFA aktif hari ini. */
export async function activeWfa(userId: string) {
  const today = new Date().toISOString().slice(0, 10);
  const { data } = await supabaseAdmin
    .from("asn_wfa_assignment")
    .select("id,alasan,nomor_surat,mulai,selesai,status")
    .eq("user_id", userId)
    .eq("status", "approved")
    .lte("mulai", today)
    .gte("selesai", today)
    .limit(1);
  return data?.[0] ?? null;
}

/** Hapus foto selfie absensi yang berusia lebih dari 7 hari. */
export async function purgeExpiredAbsensiFoto(limit = 500) {
  const cutoff = new Date(Date.now() - FOTO_RETENTION_DAYS * 86_400_000).toISOString();
  const { data, error } = await supabaseAdmin
    .from("absensi_asn")
    .select("id,foto_url")
    .not("foto_url", "is", null)
    .is("foto_deleted_at", null)
    .lt("waktu", cutoff)
    .limit(limit);
  if (error) throw new Error(error.message);
  const rows = data ?? [];
  if (rows.length === 0) return { deleted: 0 };
  const paths = rows.map((r) => r.foto_url as string);
  const { error: rmErr } = await supabaseAdmin.storage.from("absensi-foto").remove(paths);
  if (rmErr) throw new Error(rmErr.message);
  const now = new Date().toISOString();
  await supabaseAdmin
    .from("absensi_asn")
    .update({ foto_url: null, foto_deleted_at: now })
    .in(
      "id",
      rows.map((r) => r.id),
    );
  return { deleted: rows.length };
}

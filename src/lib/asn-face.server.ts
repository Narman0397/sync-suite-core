// Helper server-only untuk biometrik wajah terpusat & retensi foto absensi.
import { supabaseAdmin } from "@/integrations/supabase/client.server";
import {
  adaptEmbedding,
  averageEmbeddings,
  cosineSimilarity,
  extractFaceEmbedding,
  imageQuality,
  FACE_ADAPT_THRESHOLD,
  FACE_MATCH_THRESHOLD,
} from "@/lib/face-embedding.server";

export const MIN_FACE_SAMPLES = 3;
export const FOTO_RETENTION_DAYS = 7;

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
  // Sampel harus berasal dari orang yang sama — konsistensi antar-sampel.
  for (let i = 1; i < vectors.length; i++) {
    if (cosineSimilarity(vectors[0], vectors[i]) < 0.6)
      throw new Error("Sampel wajah tidak konsisten. Ulangi perekaman dengan latar yang sama.");
  }
  const embedding = averageEmbeddings(vectors);
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
 * Cocokkan foto selfie absensi dengan template di database (server-side).
 * Bila keyakinan tinggi, template diperbarui bertahap (EMA) agar mengikuti
 * perubahan wajar wajah ASN.
 */
export async function verifyFace(userId: string, photo: string) {
  const tpl = await getFaceTemplate(userId);
  if (!tpl) return { enrolled: false, verified: false, score: null as number | null };
  const fresh = extractFaceEmbedding(photo);
  const score = cosineSimilarity(tpl.embedding, fresh);
  const verified = score >= FACE_MATCH_THRESHOLD;
  if (verified && score >= FACE_ADAPT_THRESHOLD) {
    const next = adaptEmbedding(tpl.embedding, fresh);
    await supabaseAdmin
      .from("asn_face_template")
      .update({
        embedding: next,
        adapt_count: tpl.adapt_count + 1,
        updated_at: new Date().toISOString(),
      })
      .eq("id", tpl.id);
  }
  return { enrolled: true, verified, score: Number(score.toFixed(4)) };
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

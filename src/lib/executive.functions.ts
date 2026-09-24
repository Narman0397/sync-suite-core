// Executive / Pemda summary — dipanggil dari dashboard /executive & /pemda.
// Authorization dilakukan via RPC SECURITY DEFINER + RLS pemda_read_all /
// pimpinan_read_all. Tetap memerlukan session (requireSupabaseAuth).
import { createServerFn } from "@tanstack/react-start";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";
import { getUserContext } from "@/features/rbac/guards";
import type { SkorRow } from "@/lib/kinerja.functions";

async function requireExecutive(
  supabase: Parameters<typeof getUserContext>[0],
  userId: string,
) {
  const authz = await getUserContext(supabase, userId);
  if (!authz.isExecutiveView) throw new Error("Akses dashboard pimpinan ditolak.");
}

// Kontrak dashboard pimpinan. Nilai null = metrik tidak disediakan oleh RPC
// executive_summary pada database ini (bukan angka nol).
export type ExecutiveSummary = {
  kabupaten: {
    permohonan_total: number | null;
    permohonan_bulan: number | null;
    permohonan_selesai: number | null;
    permohonan_diproses: number | null;
    permohonan_baru: number | null;
    permohonan_overdue: number | null;
    laporan_total: number | null;
    laporan_open: number | null;
    laporan_baru: number | null;
    laporan_selesai: number | null;
    cuti_pending: number | null;
    dataset_submission_total: number | null;
    dataset_submission_selesai: number | null;
    ikm_responses_total: number | null;
    ikm_periode: string | null;
    aset_total: number | null;
    aset_rusak: number | null;
    ikm_responses_30d: number | null;
    opd_count: number | null;
    layanan_total: number | null;
    user_total: number | null;
    asn_count: number | null;
    avg_rating: number | null;
    izin_pending: number | null;
    dataset_template_active: number | null;
    dataset_submission_active: number | null;
    dataset_review_pending: number | null;
    sla_on_time_pct: number | null;
  };
  generated_at: string | null;
};

type Raw = Record<string, unknown>;

function num(src: Raw, ...keys: string[]): number | null {
  for (const k of keys) {
    const v = src[k];
    if (typeof v === "number" && Number.isFinite(v)) return v;
    if (typeof v === "string" && v.trim() !== "" && Number.isFinite(Number(v))) return Number(v);
  }
  return null;
}

function normalizeSummary(data: Raw): ExecutiveSummary {
  // Beberapa deployment mengembalikan objek datar, lainnya membungkusnya di "kabupaten".
  const kab = (typeof data.kabupaten === "object" && data.kabupaten !== null
    ? (data.kabupaten as Raw)
    : data) as Raw;
  const generated = data.generated_at ?? kab.generated_at;
  return {
    kabupaten: {
      permohonan_total: num(kab, "permohonan_total", "total_permohonan"),
      permohonan_bulan: num(kab, "permohonan_bulan", "permohonan_bulan_ini"),
      permohonan_selesai: num(kab, "permohonan_selesai"),
      permohonan_diproses: num(kab, "permohonan_diproses"),
      permohonan_baru: num(kab, "permohonan_baru"),
      permohonan_overdue: num(kab, "permohonan_overdue"),
      laporan_total: num(kab, "laporan_total"),
      laporan_open: num(kab, "laporan_open"),
      aset_total: num(kab, "aset_total"),
      aset_rusak: num(kab, "aset_rusak"),
      ikm_responses_30d: num(kab, "ikm_responses_30d"),
      opd_count: num(kab, "opd_count", "total_opd"),
      layanan_total: num(kab, "layanan_total", "total_layanan"),
      user_total: num(kab, "user_total", "total_user"),
      asn_count: num(kab, "asn_count"),
      avg_rating: num(kab, "avg_rating"),
      izin_pending: num(kab, "izin_pending"),
      dataset_template_active: num(kab, "dataset_template_active"),
      dataset_submission_active: num(kab, "dataset_submission_active"),
      dataset_review_pending: num(kab, "dataset_review_pending"),
      sla_on_time_pct: num(kab, "sla_on_time_pct"),
      laporan_baru: num(kab, "laporan_baru"),
      laporan_selesai: num(kab, "laporan_selesai"),
      cuti_pending: num(kab, "cuti_pending"),
      dataset_submission_total: num(kab, "dataset_submission_total"),
      dataset_submission_selesai: num(kab, "dataset_submission_selesai"),
      ikm_responses_total: num(kab, "ikm_responses_total"),
      ikm_periode: typeof kab.ikm_periode === "string" ? kab.ikm_periode : null,
    },
    generated_at: typeof generated === "string" ? generated : null,
  };
}

// CLONE_EXCEPTION #002 (lanjutan, additive): RPC executive_summary pada database
// ini hanya menyediakan sebagian metrik. Metrik lain diisi dari sumber existing
// yang memang dapat dibaca akun pimpinan (RLS tetap berlaku). Bila sumber tidak
// dapat dibaca atau query gagal, nilainya tetap null — tidak pernah dipaksa ke 0.
/* eslint-disable @typescript-eslint/no-explicit-any */
async function safeCount(
  sb: any,
  table: string,
  apply?: (q: any) => any,
): Promise<number | null> {
  try {
    const base = sb.from(table).select("id", { count: "exact", head: true });
    const { count, error } = await (apply ? apply(base) : base);
    if (error) return null;
    return typeof count === "number" ? count : null;
  } catch {
    return null;
  }
}

async function slaOnTimePct(sb: any): Promise<number | null> {
  try {
    const { data, error } = await sb.rpc("opd_kinerja_agg");
    if (error || !Array.isArray(data)) return null;
    let onTime = 0;
    let base = 0;
    for (const row of data as Array<Record<string, unknown>>) {
      onTime += Number(row.tepat_waktu) || 0;
      base += Number(row.selesai_dengan_sla) || 0;
    }
    if (base <= 0) return null; // sumber ada, data belum cukup untuk KPI
    return (onTime / base) * 100;
  } catch {
    return null;
  }
}

async function augment(sb: any, summary: ExecutiveSummary): Promise<ExecutiveSummary> {
  const kab = summary.kabupaten;
  const [overdue, sla, asetTotal, asetRusak, asnCount, datasetTemplate] = await Promise.all([
    kab.permohonan_overdue == null
      ? safeCount(sb, "permohonan", (q: any) =>
          q.not("status", "in", "(selesai,ditolak,dibatalkan)").lt("tenggat", new Date().toISOString()),
        )
      : Promise.resolve(kab.permohonan_overdue),
    kab.sla_on_time_pct == null ? slaOnTimePct(sb) : Promise.resolve(kab.sla_on_time_pct),
    kab.aset_total == null ? safeCount(sb, "aset") : Promise.resolve(kab.aset_total),
    kab.aset_rusak == null
      ? safeCount(sb, "aset", (q: any) => q.eq("status", "rusak"))
      : Promise.resolve(kab.aset_rusak),
    kab.asn_count == null
      ? safeCount(sb, "profiles", (q: any) => q.not("asn_type", "is", null))
      : Promise.resolve(kab.asn_count),
    kab.dataset_template_active == null
      ? safeCount(sb, "dataset_template", (q: any) => q.eq("aktif", true))
      : Promise.resolve(kab.dataset_template_active),
  ]);
  return {
    ...summary,
    kabupaten: {
      ...kab,
      permohonan_overdue: overdue,
      sla_on_time_pct: sla,
      aset_total: asetTotal,
      aset_rusak: asetRusak,
      asn_count: asnCount,
      dataset_template_active: datasetTemplate,
    },
  };
}
/* eslint-enable @typescript-eslint/no-explicit-any */

export const getExecutiveSummary = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { supabase } = context;
    await requireExecutive(supabase, context.userId);
    const { data, error } = await supabase.rpc("executive_summary");
    if (error) throw new Error(error.message);
    if (!data || typeof data !== "object") {
      throw new Error("Kontrak data ringkasan pimpinan tidak valid.");
    }
    return augment(supabase, normalizeSummary(data as Raw));
  });


export const getExecutiveOpdScores = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    await requireExecutive(context.supabase, context.userId);
    const { data, error } = await context.supabase.rpc("opd_skor_komposit");
    if (error) throw new Error(error.message);
    return { rows: (data ?? []) as SkorRow[] };
  });

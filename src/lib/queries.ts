import { queryOptions, type QueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { cachedFetch, invalidateCache } from "@/lib/postgrest-cache";

type BackendReadError = { code?: string; message?: string };

function isSchemaCacheError(error: unknown): boolean {
  if (!error || typeof error !== "object") return false;
  const { code, message } = error as BackendReadError;
  return (
    code === "PGRST200" ||
    code === "PGRST204" ||
    code === "PGRST205" ||
    /schema cache|Could not find the table|Could not find a relationship|column .* does not exist/i.test(
      message ?? "",
    )
  );
}

function fallbackOnSchemaCacheError<T>(error: unknown, fallback: T, label: string): T | undefined {
  if (!error) return undefined;
  if (!isSchemaCacheError(error)) throw error;
  console.error(`[public-data:${label}] backend schema is not ready`, error);
  return fallback;
}

/**
 * Invalidasi cache untuk halaman publik setelah mutasi CMS.
 * Dipanggil dari admin (CMS, OPD) agar pengunjung melihat data terbaru
 * tanpa perlu reload paksa.
 */
export const invalidateBerita = (qc: QueryClient) => {
  invalidateCache("berita:");
  invalidateCache("home:");
  return qc.invalidateQueries({ queryKey: ["berita"] });
};

export const invalidateLayanan = (qc: QueryClient) => {
  invalidateCache("layanan:");
  invalidateCache("home:");
  return Promise.all([
    qc.invalidateQueries({ queryKey: ["layanan"] }),
    qc.invalidateQueries({ queryKey: ["layanan", "count-by-opd"] }),
  ]);
};

export const invalidateOpd = (qc: QueryClient) => {
  invalidateCache("opd:");
  invalidateCache("layanan:");
  return Promise.all([
    qc.invalidateQueries({ queryKey: ["opd"] }),
    qc.invalidateQueries({ queryKey: ["layanan"] }),
  ]);
};

export type Berita = {
  id: string;
  judul: string;
  ringkasan: string | null;
  isi: string;
  gambar_url: string | null;
  published_at: string | null;
};

export type Opd = {
  id: string;
  singkatan: string;
  nama: string;
  kategori: string[];
};

export type LayananRingkas = {
  id: string;
  judul: string;
  slug: string;
  deskripsi: string | null;
  persyaratan?: string | null;
};

export type HomeStats = {
  layananOnline: number;
  permohonanBulanIni: number;
  datasetTerbuka: number;
  kepuasanPersen: number | null;
};

export const homeStatsQueryOptions = () =>
  queryOptions({
    queryKey: ["home", "stats"],
    queryFn: (): Promise<HomeStats> =>
      cachedFetch("home:stats", 60_000, async () => {
        const [layananRes, permohonanRes, datasetRes, ratingRes] = await Promise.all([
          supabase
            .from("layanan_publik")
            .select("*", { count: "exact", head: true })
            .eq("aktif", true),
          supabase.rpc("count_permohonan_bulan_ini"),
          supabase
            .from("data_terpadu_item")
            .select("*", { count: "exact", head: true })
            .eq("aktif", true),
          supabase
            .from("permohonan_rating")
            .select("skor")
            .order("created_at", { ascending: false })
            .limit(500),
        ]);

        const ratings = isSchemaCacheError(ratingRes.error)
          ? []
          : ((ratingRes.data ?? []) as { skor: number }[]);
        const avg =
          ratings.length > 0 ? ratings.reduce((s, r) => s + r.skor, 0) / ratings.length : null;
        const kepuasanPersen = avg !== null ? (avg / 10) * 100 : null;

        return {
          layananOnline: isSchemaCacheError(layananRes.error) ? 0 : (layananRes.count ?? 0),
          permohonanBulanIni: isSchemaCacheError(permohonanRes.error)
            ? 0
            : ((permohonanRes.data as number | null) ?? 0),
          datasetTerbuka: isSchemaCacheError(datasetRes.error) ? 0 : (datasetRes.count ?? 0),
          kepuasanPersen,
        };
      }),
    // Home stats change slowly; cache 10 minutes so most renders skip DB work.
    staleTime: 10 * 60_000,
    gcTime: 30 * 60_000,
  });

export type LayananWithOpd = {
  id: string;
  judul: string;
  slug: string;
  deskripsi: string | null;
  sla_hari: number;
  urutan: number;
  opd: { id: string; singkatan: string; nama: string; kategori: string[] } | null;
};

export const layananAllWithOpdQueryOptions = () =>
  queryOptions({
    queryKey: ["layanan", "all-with-opd"],
    queryFn: (): Promise<LayananWithOpd[]> =>
      cachedFetch("layanan:all-with-opd", 60_000, async () => {
        const { data, error } = await supabase
          .from("layanan_publik")
          .select(
            "id,judul,slug,deskripsi,sla_hari,urutan,opd:opd!opd_id(id,singkatan,nama,kategori)",
          )
          .eq("aktif", true)
          .order("urutan");
        const fallback = fallbackOnSchemaCacheError(error, [] as LayananWithOpd[], "layanan-all");
        if (fallback) return fallback;
        return (data ?? []) as unknown as LayananWithOpd[];
      }),
    staleTime: 5 * 60_000,
    gcTime: 10 * 60_000,
  });

export const layananHomeQueryOptions = () =>
  queryOptions({
    queryKey: ["layanan", "home-top"],
    queryFn: (): Promise<LayananRingkas[]> =>
      cachedFetch("layanan:home-top", 60_000, async () => {
        const { data, error } = await supabase
          .from("layanan_publik")
          .select("id,judul,slug,deskripsi")
          .eq("aktif", true)
          .order("urutan")
          .limit(6);
        const fallback = fallbackOnSchemaCacheError(error, [] as LayananRingkas[], "layanan-home");
        if (fallback) return fallback;
        return (data ?? []) as LayananRingkas[];
      }),
    staleTime: 5 * 60_000,
    gcTime: 10 * 60_000,
  });

export type LayananFaqItem = { q: string; a: string };
export type LayananDetail = {
  id: string;
  judul: string;
  slug: string;
  deskripsi: string | null;
  persyaratan: string | null;
  alur: string | null;
  opd_id: string | null;
  sla_hari: number;
  dasar_hukum: string | null;
  biaya: string | null;
  produk_layanan: string | null;
  jam_pelayanan: string | null;
  sarana_prasarana: string | null;
  kompetensi_pelaksana: string | null;
  jumlah_pelaksana: number | null;
  jaminan_pelayanan: string | null;
  jaminan_keamanan: string | null;
  mekanisme_pengaduan: string | null;
  evaluasi_kinerja: string | null;
  maklumat_pelayanan: string | null;
  faq: LayananFaqItem[];
};

const FIVE_MIN = 5 * 60_000;
const TEN_MIN = 10 * 60_000;

export const beritaListQueryOptions = () =>
  queryOptions({
    queryKey: ["berita", "list"],
    queryFn: (): Promise<Berita[]> =>
      cachedFetch("berita:list", 60_000, async () => {
        const { data, error } = await supabase
          .from("berita")
          .select("id,judul,ringkasan,isi,gambar_url,published_at")
          .eq("status", "terbit")
          .order("published_at", { ascending: false })
          .limit(30);
        const fallback = fallbackOnSchemaCacheError(error, [] as Berita[], "berita-list");
        if (fallback) return fallback;
        return (data ?? []) as Berita[];
      }),
    staleTime: FIVE_MIN,
    gcTime: TEN_MIN,
  });

export const opdListQueryOptions = () =>
  queryOptions({
    queryKey: ["opd", "list"],
    queryFn: (): Promise<Opd[]> =>
      cachedFetch("opd:list", 120_000, async () => {
        const { data, error } = await supabase
          .from("opd")
          .select("id,singkatan,nama,kategori")
          .order("singkatan");
        const fallback = fallbackOnSchemaCacheError(error, [] as Opd[], "opd-list");
        if (fallback) return fallback;
        return (data ?? []) as Opd[];
      }),
    staleTime: TEN_MIN,
    gcTime: TEN_MIN * 2,
  });

export const layananCountByOpdQueryOptions = () =>
  queryOptions({
    queryKey: ["layanan", "count-by-opd"],
    queryFn: (): Promise<Record<string, number>> =>
      cachedFetch("layanan:count-by-opd", 60_000, async () => {
        const { data, error } = await supabase
          .from("layanan_publik")
          .select("opd_id")
          .eq("aktif", true)
          .not("opd_id", "is", null);
        const fallback = fallbackOnSchemaCacheError(
          error,
          {} as Record<string, number>,
          "layanan-count-by-opd",
        );
        if (fallback) return fallback;
        const counts: Record<string, number> = {};
        ((data ?? []) as { opd_id: string | null }[]).forEach((x) => {
          if (x.opd_id) counts[x.opd_id] = (counts[x.opd_id] ?? 0) + 1;
        });
        return counts;
      }),
    staleTime: TEN_MIN,
    gcTime: TEN_MIN * 2,
  });

export const opdBySingkatanQueryOptions = (singkatan: string) =>
  queryOptions({
    queryKey: ["opd", "by-singkatan", singkatan],
    queryFn: async (): Promise<Opd | null> => {
      const { data, error } = await supabase
        .from("opd")
        .select("id,singkatan,nama,kategori")
        .eq("singkatan", singkatan)
        .maybeSingle();
      const fallback = fallbackOnSchemaCacheError(error, null as Opd | null, "opd-by-singkatan");
      if (fallback !== undefined) return fallback;
      return (data ?? null) as Opd | null;
    },
    staleTime: TEN_MIN,
    gcTime: TEN_MIN * 2,
  });

export const layananByOpdIdQueryOptions = (opdId: string) =>
  queryOptions({
    queryKey: ["layanan", "by-opd", opdId],
    queryFn: async (): Promise<LayananRingkas[]> => {
      const { data, error } = await supabase
        .from("layanan_publik")
        .select("id,judul,slug,deskripsi,persyaratan")
        .eq("aktif", true)
        .eq("opd_id", opdId)
        .order("urutan");
      const fallback = fallbackOnSchemaCacheError(error, [] as LayananRingkas[], "layanan-by-opd");
      if (fallback) return fallback;
      return (data ?? []) as LayananRingkas[];
    },
    staleTime: FIVE_MIN,
    gcTime: TEN_MIN,
  });

export const layananBySlugQueryOptions = (slug: string) =>
  queryOptions({
    queryKey: ["layanan", "by-slug", slug],
    queryFn: async (): Promise<LayananDetail | null> => {
      const { data, error } = await supabase
        .from("layanan_publik")
        .select(
          "id,judul,slug,deskripsi,persyaratan,alur,opd_id,sla_hari,dasar_hukum,biaya,produk_layanan,jam_pelayanan,sarana_prasarana,kompetensi_pelaksana,jumlah_pelaksana,jaminan_pelayanan,jaminan_keamanan,mekanisme_pengaduan,evaluasi_kinerja,maklumat_pelayanan,faq"
        )
        .eq("slug", slug)
        .eq("aktif", true)
        .maybeSingle();
      const fallback = fallbackOnSchemaCacheError(error, null as LayananDetail | null, "layanan-by-slug");
      if (fallback !== undefined) return fallback;
      const row = (data ?? null) as (Omit<LayananDetail, "faq"> & { faq: unknown }) | null;
      if (!row) return null;
      return { ...row, faq: Array.isArray(row.faq) ? (row.faq as LayananFaqItem[]) : [] };
    },
    staleTime: FIVE_MIN,
    gcTime: TEN_MIN,
  });

export const opdByIdQueryOptions = (opdId: string) =>
  queryOptions({
    queryKey: ["opd", "by-id", opdId],
    queryFn: async (): Promise<Opd | null> => {
      const { data, error } = await supabase
        .from("opd")
        .select("id,singkatan,nama,kategori")
        .eq("id", opdId)
        .maybeSingle();
      const fallback = fallbackOnSchemaCacheError(error, null as Opd | null, "opd-by-id");
      if (fallback !== undefined) return fallback;
      return (data ?? null) as Opd | null;
    },
    staleTime: TEN_MIN,
    gcTime: TEN_MIN * 2,
  });

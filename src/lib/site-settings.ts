// Helper klien untuk membaca/menulis app_setting & data desa.
import { supabase } from "@/integrations/supabase/client";

export type Desa = { id: string; nama: string; kecamatan: string | null; aktif: boolean };

export async function fetchDesaList(onlyAktif = true): Promise<Desa[]> {
  let q = supabase.from("desa").select("id,nama,kecamatan,aktif").order("nama");
  if (onlyAktif) q = q.eq("aktif", true);
  const { data } = await q;
  return (data ?? []) as Desa[];
}

export async function getPermohonanVerificationRequired(): Promise<boolean> {
  const { data } = await supabase
    .from("app_setting")
    .select("value")
    .eq("key", "permohonan_require_verification")
    .maybeSingle();
  const v = (data?.value as { required?: boolean } | null) ?? null;
  return !!v?.required;
}

export type SiteBranding = {
  // identitas
  logo_url: string;
  brand_prefix: string;
  brand_name: string;
  admin_brand_name: string;
  top_bar_text: string;
  // SEO
  meta_site_title: string;
  meta_site_description: string;
  // hero
  hero_bg_url: string;
  hero_eyebrow: string;
  hero_title_line1: string;
  hero_title_line2: string;
  hero_title_line3: string;
  hero_subtitle: string;
  hero_btn_primary: string;
  hero_btn_secondary: string;
  // direktori OPD
  direktori_eyebrow: string;
  direktori_title: string;
  direktori_desc: string;
  // 3 pilar
  pilar_1_title: string;
  pilar_1_desc: string;
  pilar_2_title: string;
  pilar_2_desc: string;
  pilar_3_title: string;
  pilar_3_desc: string;
  // CTA
  cta_title: string;
  cta_desc: string;
  cta_btn_primary: string;
  cta_btn_secondary: string;
  // footer
  footer_org: string;
  footer_tagline: string;
  footer_description: string;
  footer_address: string;
  footer_phone: string;
  footer_email: string;
};

export const DEFAULT_BRANDING: SiteBranding = {
  logo_url: "",
  brand_prefix: "PEMERINTAH KABUPATEN",
  brand_name: "Nama Kabupaten",
  admin_brand_name: "Dashboard Admin",
  top_bar_text: "Portal Resmi Pemerintah Kabupaten",
  meta_site_title: "Portal Resmi Pemerintah Kabupaten",
  meta_site_description: "Portal resmi pelayanan publik dan satu data Pemerintah Kabupaten.",
  hero_bg_url: "",
  hero_eyebrow: "Portal Resmi Pemerintah",
  hero_title_line1: "Satu Pintu,",
  hero_title_line2: "Satu Data,",
  hero_title_line3: "Satu Pelayanan.",
  hero_subtitle:
    "Akses seluruh layanan publik dan data pemerintah terpadu dalam satu tempat — cepat, transparan, dan terverifikasi.",
  hero_btn_primary: "Mulai Layanan",
  hero_btn_secondary: "Lihat Satu Data",
  direktori_eyebrow: "Direktori OPD",
  direktori_title: "Dinas & Perangkat Daerah",
  direktori_desc: "Kenali setiap OPD dan layanan yang dikelolanya.",
  pilar_1_title: "Satu Data Terpadu",
  pilar_1_desc:
    "Semua dataset pemerintah dalam satu standar — terbuka, terverifikasi, dan dapat diunduh.",
  pilar_2_title: "Pelayanan Sentralistik",
  pilar_2_desc:
    "Warga cukup satu akun untuk seluruh layanan: adminduk, perizinan, kesehatan, hingga pajak.",
  pilar_3_title: "Transparansi Real-time",
  pilar_3_desc: "Dashboard kinerja, anggaran, dan capaian program publik dapat dipantau langsung.",
  cta_title: "Punya keluhan atau aspirasi?",
  cta_desc:
    "Sampaikan langsung melalui kanal LAPOR! Setiap laporan dipantau dan ditindaklanjuti oleh OPD terkait.",
  cta_btn_primary: "Lapor Sekarang",
  cta_btn_secondary: "Tentang Pemerintah",
  footer_org: "Pemerintah Kabupaten",
  footer_tagline: "Melayani dengan integritas & data",
  footer_description:
    "Situs resmi pemusatan pelayanan publik dan data terintegrasi. Transparan, terpadu, dan dapat diakses kapan saja.",
  footer_address: "—",
  footer_phone: "—",
  footer_email: "—",
};

const BRANDING_LS_KEY = "site_branding_cache_v1";

function readBrandingCache(): SiteBranding | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(BRANDING_LS_KEY);
    if (!raw) return null;
    return { ...DEFAULT_BRANDING, ...(JSON.parse(raw) as Partial<SiteBranding>) };
  } catch {
    return null;
  }
}

function writeBrandingCache(b: SiteBranding) {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(BRANDING_LS_KEY, JSON.stringify(b));
    window.dispatchEvent(new CustomEvent("site-branding-updated", { detail: b }));
  } catch {
    // ignore storage / event errors (mis. quota / SSR)
  }
}

// Salinan terakhir yang berhasil dibaca, hidup selama proses berjalan.
// Dipakai juga saat SSR (tidak ada localStorage di server) supaya gangguan
// koneksi sesaat tidak membuat identitas situs jatuh ke teks bawaan.
let lastKnownBranding: SiteBranding | null = null;

const BRANDING_TIMEOUT_MS = 8_000;
const BRANDING_RETRY_DELAYS = [400, 1_200];

async function fetchBrandingOnce(): Promise<Partial<SiteBranding> | null> {
  let filter = supabase.from("app_setting").select("value").eq("key", "site_branding");
  if (typeof AbortSignal !== "undefined" && typeof AbortSignal.timeout === "function") {
    filter = filter.abortSignal(AbortSignal.timeout(BRANDING_TIMEOUT_MS));
  }
  const { data, error } = await filter.maybeSingle();
  // error = gangguan jaringan/RLS → lempar agar dicoba ulang.
  if (error) throw new Error(error.message);
  // data null = baris memang belum ada (bukan gangguan).
  return (data?.value as Partial<SiteBranding> | null) ?? null;
}

export async function getSiteBranding(): Promise<SiteBranding> {
  for (let attempt = 0; ; attempt++) {
    try {
      const value = await fetchBrandingOnce();
      if (value == null) {
        // Baris belum ada: jangan timpa cache dengan nilai bawaan.
        return lastKnownBranding ?? readBrandingCache() ?? DEFAULT_BRANDING;
      }
      const merged = { ...DEFAULT_BRANDING, ...value };
      lastKnownBranding = merged;
      writeBrandingCache(merged);
      return merged;
    } catch {
      if (attempt < BRANDING_RETRY_DELAYS.length) {
        await new Promise((r) => setTimeout(r, BRANDING_RETRY_DELAYS[attempt]));
        continue;
      }
      // Gagal total: pakai salinan terakhir yang diketahui benar.
      return lastKnownBranding ?? readBrandingCache() ?? DEFAULT_BRANDING;
    }
  }
}


export async function setSiteBranding(b: SiteBranding): Promise<void> {
  const { error } = await supabase
    .from("app_setting")
    .upsert(
      { key: "site_branding", value: b as unknown as never, public_visible: true },
      { onConflict: "key" },
    );
  if (error) throw error;
  lastKnownBranding = b;
  writeBrandingCache(b);
}


import { useEffect } from "react";
import { queryOptions, useQuery, useQueryClient } from "@tanstack/react-query";

export const SITE_BRANDING_QUERY_KEY = ["site-branding"] as const;

export const siteBrandingQueryOptions = () =>
  queryOptions({
    queryKey: SITE_BRANDING_QUERY_KEY,
    queryFn: getSiteBranding,
    staleTime: 5 * 60_000,
    gcTime: 30 * 60_000,
    // TANPA initialData: root loader memanggil ensureQueryData() sehingga data
    // asli sudah ada saat SSR dan ikut ter-dehydrate ke klien. initialData akan
    // membuat ensureQueryData menganggap cache sudah terisi (tidak fetch),
    // sehingga HTML server memakai nilai bawaan sementara klien memakai data
    // asli → hydration mismatch (React #418).
  });


/**
 * Hook konsumen branding. Menggunakan TanStack Query sebagai singleton
 * cache — semua pemanggil berbagi 1 fetch & 1 cache entry. Window event
 * `site-branding-updated` (dipancarkan oleh writer di tab yang sama atau
 * tab lain via storage) diteruskan ke cache lewat `setQueryData`.
 */
export function useSiteBranding(): SiteBranding {
  const qc = useQueryClient();
  const { data } = useQuery(siteBrandingQueryOptions());

  // Terapkan cache localStorage SETELAH hidrasi selesai, sehingga render
  // pertama tetap sama persis dengan HTML SSR.
  useEffect(() => {
    const state = qc.getQueryState(SITE_BRANDING_QUERY_KEY);
    if (state?.dataUpdatedAt) return; // sudah ada data segar dari server
    const cached = readBrandingCache();
    if (cached) qc.setQueryData(SITE_BRANDING_QUERY_KEY, cached);
  }, [qc]);

  useEffect(() => {
    if (typeof window === "undefined") return;
    const onUpdate = (e: Event) => {
      const detail = (e as CustomEvent<SiteBranding>).detail;
      if (detail) qc.setQueryData(SITE_BRANDING_QUERY_KEY, detail);
      else qc.invalidateQueries({ queryKey: SITE_BRANDING_QUERY_KEY });
    };
    // Saat koneksi pulih, ambil ulang identitas situs secara diam-diam.
    const onOnline = () => qc.invalidateQueries({ queryKey: SITE_BRANDING_QUERY_KEY });
    window.addEventListener("site-branding-updated", onUpdate);
    window.addEventListener("online", onOnline);
    return () => {
      window.removeEventListener("site-branding-updated", onUpdate);
      window.removeEventListener("online", onOnline);
    };
  }, [qc]);
  return data ?? lastKnownBranding ?? DEFAULT_BRANDING;
}



export async function getShowOpdDirectory(): Promise<boolean> {
  const { data } = await supabase
    .from("app_setting")
    .select("value")
    .eq("key", "show_opd_directory")
    .maybeSingle();
  const v = (data?.value as { visible?: boolean } | null) ?? null;
  return v?.visible !== false;
}

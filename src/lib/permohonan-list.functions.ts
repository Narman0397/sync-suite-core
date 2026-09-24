import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyClient = any;
async function getAdmin(): Promise<AnyClient> {
  const mod = await import("@/integrations/supabase/client.server");
  return mod.supabaseAdmin as AnyClient;
}

// List permohonan milik pemohon yang sedang login.
export const listMyPermohonan = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const supabaseAdmin = await getAdmin();
    const userId = context.userId;
    const { data: rows, error } = await supabaseAdmin
      .from("permohonan")
      .select(
        "id, kode, judul, kategori, status, tanggal_masuk, wakil_ambil_nama, wakil_ambil_nik, opd:opd!opd_id(singkatan)",
      )
      .eq("pemohon_id", userId)
      .order("tanggal_masuk", { ascending: false })
      .limit(200);
    if (error) throw new Error(error.message);

    const list = (rows ?? []) as Array<{
      id: string;
      status: string;
    }>;
    const finalIds = list
      .filter((r) => r.status === "selesai" || r.status === "ditolak" || r.status === "diproses")
      .map((r) => r.id);

    let riwayat: Array<{ permohonan_id: string; catatan: string | null; created_at: string }> = [];
    let rating: Array<{ permohonan_id: string; skor: number; komentar: string | null }> = [];
    if (finalIds.length > 0) {
      const [{ data: rws }, { data: rts }] = await Promise.all([
        supabaseAdmin
          .from("permohonan_riwayat")
          .select("permohonan_id, catatan, created_at")
          .in("permohonan_id", finalIds)
          .not("catatan", "is", null)
          .order("created_at", { ascending: false }),
        supabaseAdmin
          .from("permohonan_rating")
          .select("permohonan_id, skor, komentar")
          .in("permohonan_id", finalIds)
          .eq("user_id", userId),
      ]);
      riwayat = (rws ?? []) as typeof riwayat;
      rating = (rts ?? []) as typeof rating;
    }

    return { rows: list, riwayat, rating };
  });

// List permohonan untuk admin (super admin lihat semua, lainnya sesuai opd_id).
const adminSchema = z
  .object({ opd_id: z.string().uuid().nullable().optional() })
  .strict();

export const listAdminPermohonan = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => adminSchema.parse(input ?? {}))
  .handler(async ({ data, context }) => {
    const supabaseAdmin = await getAdmin();
    const userId = context.userId;

    // Cek role
    const { data: roles } = await supabaseAdmin
      .from("user_roles")
      .select("role")
      .eq("user_id", userId);
    const roleSet = new Set((roles ?? []).map((r: { role: string }) => r.role));
    const isSuper = roleSet.has("super_admin");
    const isAdmin =
      isSuper ||
      roleSet.has("admin_opd") ||
      roleSet.has("admin_pemda") ||
      roleSet.has("admin_desa") ||
      roleSet.has("pimpinan") ||
      roleSet.has("asn");
    if (!isAdmin) throw new Error("Tidak berwenang.");

    let opdFilter = data.opd_id ?? null;
    if (!isSuper) {
      // paksa filter opd sesuai profile
      const { data: prof } = await supabaseAdmin
        .from("profiles")
        .select("opd_id")
        .eq("id", userId)
        .maybeSingle();
      opdFilter = (prof?.opd_id as string | null) ?? opdFilter;
    }

    let q = supabaseAdmin
      .from("permohonan")
      .select(
        "id,kode,judul,kategori,status,tanggal_masuk,tenggat,updated_at,opd_id,pemohon_id",
      )
      .order("tanggal_masuk", { ascending: false })
      .limit(200);
    if (opdFilter) q = q.eq("opd_id", opdFilter);
    const { data: rows, error } = await q;
    if (error) throw new Error(error.message);
    return { rows: rows ?? [] };
  });

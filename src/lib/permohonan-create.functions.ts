import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyClient = any;

async function getAdmin(): Promise<AnyClient> {
  const mod = await import("@/integrations/supabase/client.server");
  return mod.supabaseAdmin as AnyClient;
}

const createSchema = z
  .object({
    kode: z.string().trim().min(4).max(64).optional(),
    opd_id: z.string().uuid(),
    judul: z.string().trim().min(5).max(200),
    kategori: z.string().trim().min(1).max(200),
    deskripsi: z.string().trim().max(2000).nullable().optional(),
    prioritas: z.enum(["rendah", "normal", "tinggi"]),
    tenggat: z.string().datetime().nullable().optional(),
    untuk_orang_lain: z.boolean(),
    atas_nama_nama: z.string().trim().max(160).nullable().optional(),
    atas_nama_nik: z.string().trim().max(32).nullable().optional(),
    atas_nama_hp: z.string().trim().max(32).nullable().optional(),
  })
  .strict();

const berkasSchema = z
  .object({
    permohonan_id: z.string().uuid(),
    storage_path: z.string().trim().min(3).max(1000),
    nama_file: z.string().trim().max(255).nullable().optional(),
    jenis: z.string().trim().max(120).nullable().optional(),
    size_bytes: z.number().int().nonnegative().nullable().optional(),
  })
  .strict();

export const createPermohonan = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => createSchema.parse(input))
  .handler(async ({ data, context }) => {
    const supabaseAdmin = await getAdmin();
    const userId = context.userId;

    if (data.untuk_orang_lain) {
      if (!data.atas_nama_nama || data.atas_nama_nama.length < 3) {
        throw new Error("Nama pemohon (orang lain) wajib diisi.");
      }
      if (!data.atas_nama_nik || !/^\d{16}$/.test(data.atas_nama_nik)) {
        throw new Error("NIK harus 16 digit angka.");
      }
      if (!data.atas_nama_hp || data.atas_nama_hp.length < 8) {
        throw new Error("Nomor telepon wajib diisi.");
      }
    }

    const { data: row, error } = await supabaseAdmin
      .from("permohonan")
      .insert({
        kode: data.kode ?? null,
        pemohon_id: userId,
        opd_id: data.opd_id,
        judul: data.judul,
        kategori: data.kategori,
        deskripsi: data.deskripsi || null,
        prioritas: data.prioritas,
        tenggat: data.tenggat ?? null,
        untuk_orang_lain: data.untuk_orang_lain,
        atas_nama_nama: data.untuk_orang_lain ? data.atas_nama_nama ?? null : null,
        atas_nama_nik: data.untuk_orang_lain ? data.atas_nama_nik ?? null : null,
        atas_nama_hp: data.untuk_orang_lain ? data.atas_nama_hp ?? null : null,
      })
      .select("id,kode")
      .single();
    if (error) throw new Error(error.message);

    const { error: historyError } = await supabaseAdmin.from("permohonan_riwayat").insert({
      permohonan_id: row.id,
      oleh: userId,
      aksi: "Permohonan diajukan",
      catatan: "Pengajuan melalui portal warga.",
    });
    if (historyError) throw new Error(historyError.message);

    await supabaseAdmin.from("audit_log").insert({
      user_id: userId,
      aksi: "permohonan.created",
      entitas: "permohonan",
      entitas_id: row.id,
    });

    return { id: row.id as string, kode: row.kode as string };
  });

export const addPermohonanBerkas = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => berkasSchema.parse(input))
  .handler(async ({ data, context }) => {
    const supabaseAdmin = await getAdmin();
    const userId = context.userId;

    const { data: permohonan, error: readError } = await supabaseAdmin
      .from("permohonan")
      .select("id,pemohon_id")
      .eq("id", data.permohonan_id)
      .maybeSingle();
    if (readError) throw new Error(readError.message);
    if (!permohonan || permohonan.pemohon_id !== userId) {
      throw new Error("Anda tidak berwenang menambahkan berkas pada permohonan ini.");
    }

    const { error } = await supabaseAdmin.from("permohonan_berkas").insert({
      permohonan_id: data.permohonan_id,
      storage_path: data.storage_path,
      nama_file: data.nama_file ?? null,
      jenis: data.jenis ?? null,
      size_bytes: data.size_bytes ?? null,
      uploaded_by: userId,
    });
    if (error) throw new Error(error.message);

    return { ok: true };
  });
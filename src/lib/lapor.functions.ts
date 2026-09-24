// Server functions untuk fitur LAPOR! (pengaduan masyarakat).
// - getLaporanByTicket: publik + rate-limit (untuk halaman cek status)
// - getMyLaporan: autentikasi, daftar laporan milik user
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";
import { enforcePublicRateLimit } from "@/integrations/supabase/rate-limit.server";

export type LaporanPublic = {
  ticket_code: string;
  nama: string;
  kategori: string;
  lokasi: string | null;
  uraian: string;
  status: string;
  tindak_lanjut: string | null;
  created_at: string;
  updated_at: string;
};

export const getLaporanByTicket = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) =>
    z.object({ ticket: z.string().trim().min(6).max(64) }).parse(input),
  )
  .handler(async ({ data }): Promise<LaporanPublic | null> => {
    await enforcePublicRateLimit("lapor_lookup", { limit: 30, windowSec: 60 });
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { data: row, error } = await supabaseAdmin
      .from("laporan_masyarakat")
      .select(
        "ticket_code,nama,kategori,lokasi,uraian,status,tindak_lanjut,created_at,updated_at",
      )
      .eq("ticket_code", data.ticket.toUpperCase())
      .maybeSingle();
    if (error) throw new Error(error.message);
    return (row as LaporanPublic | null) ?? null;
  });

export const getMyLaporan = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { supabase, userId } = context;
    const { data, error } = await supabase
      .from("laporan_masyarakat")
      .select("id,ticket_code,kategori,uraian,status,created_at,updated_at,tindak_lanjut")
      .eq("pelapor_id", userId)
      .order("created_at", { ascending: false })
      .limit(100);
    if (error) throw new Error(error.message);
    return data ?? [];
  });

// Dipanggil dari client setelah insert laporan berhasil, untuk memicu notifikasi
// ke super_admin (dan admin_opd jika opd_id sudah diset).
export const notifyLaporanCreated = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) =>
    z.object({ ticket: z.string().trim().min(6).max(64) }).parse(input),
  )
  .handler(async ({ data }) => {
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { data: row } = await supabaseAdmin
      .from("laporan_masyarakat")
      .select("id,ticket_code,kategori,uraian,opd_id")
      .eq("ticket_code", data.ticket.toUpperCase())
      .maybeSingle();
    if (!row) return { ok: false as const };
    const { listSuperAdminIds, listOpdAdminIds, notifyRecipients } = await import(
      "@/lib/notifications.functions"
    );
    const [supers, opdAdmins] = await Promise.all([
      listSuperAdminIds(),
      row.opd_id ? listOpdAdminIds(row.opd_id as string) : Promise.resolve<string[]>([]),
    ]);
    await notifyRecipients([...supers, ...opdAdmins], {
      tipe: "lapor.new",
      judul: `Laporan baru: ${row.kategori}`,
      body: ((row.uraian ?? "") as string).slice(0, 160),
      link: "/admin/laporan",
      dedupeKey: `lapor.new:${row.id}`,
    });
    return { ok: true as const };
  });

// Update laporan oleh admin: status/opd/tindak_lanjut. Notifikasi pelapor bila
// ada perubahan status atau tindak_lanjut.
export const updateLaporanAdmin = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) =>
    z
      .object({
        id: z.string().uuid(),
        status: z.string().max(40).optional(),
        opd_id: z.string().uuid().nullable().optional(),
        tindak_lanjut: z.string().max(4000).nullable().optional(),
      })
      .parse(input),
  )
  .handler(async ({ data }) => {
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { data: before } = await supabaseAdmin
      .from("laporan_masyarakat")
      .select("id,status,tindak_lanjut,pelapor_id,ticket_code,kategori")
      .eq("id", data.id)
      .maybeSingle();
    if (!before) throw new Error("Laporan tidak ditemukan");
    const patch: Record<string, unknown> = {};
    if (data.status !== undefined) patch.status = data.status;
    if (data.opd_id !== undefined) patch.opd_id = data.opd_id;
    if (data.tindak_lanjut !== undefined) patch.tindak_lanjut = data.tindak_lanjut;
    if (Object.keys(patch).length === 0) return { ok: true as const };
    const { error } = await supabaseAdmin
      .from("laporan_masyarakat")
      .update(patch as never)
      .eq("id", data.id);
    if (error) throw new Error(error.message);
    const statusChanged =
      data.status !== undefined && data.status !== (before.status as string | null);
    const followupChanged =
      data.tindak_lanjut !== undefined &&
      (data.tindak_lanjut ?? "") !== ((before.tindak_lanjut ?? "") as string);
    if (before.pelapor_id && (statusChanged || followupChanged)) {
      try {
        const { enqueueNotification } = await import("@/lib/notifications.functions");
        await enqueueNotification({
          userId: before.pelapor_id as string,
          tipe: "lapor.status_changed",
          judul: `Laporan ${before.ticket_code}: ${data.status ?? before.status}`,
          body:
            ((data.tindak_lanjut ?? before.tindak_lanjut ?? "") as string).slice(0, 160) || null,
          link: `/lapor/status?ticket=${before.ticket_code}`,
          dedupeKey: `lapor.status:${before.id}:${data.status ?? before.status}`,
        });
      } catch {
        /* ignore */
      }
    }
    return { ok: true as const };
  });

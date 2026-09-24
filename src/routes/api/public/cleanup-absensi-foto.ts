// Pembersihan otomatis foto selfie absensi berusia > 7 hari (kepatuhan UU PDP).
// Dipanggil penjadwal (cron) harian. Wajib menyertakan rahasia cron.
import { createFileRoute } from "@tanstack/react-router";
import { verifyCronCaller } from "@/lib/cron-auth.server";

export const Route = createFileRoute("/api/public/cleanup-absensi-foto")({
  server: {
    handlers: {
      POST: async ({ request }) => {
        const unauth = verifyCronCaller(request);
        if (unauth) return unauth;
        const { purgeExpiredAbsensiFoto } = await import("@/lib/asn-face.server");
        try {
          const res = await purgeExpiredAbsensiFoto();
          const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
          if (res.deleted > 0) {
            await supabaseAdmin.from("audit_log").insert({
              aksi: "absensi.foto_retensi_cleanup",
              entitas: "absensi_asn",
              data_sesudah: { deleted: res.deleted, retention_days: 7 } as never,
            });
          }
          return Response.json({ ok: true, ...res });
        } catch (e) {
          return Response.json({ ok: false, error: (e as Error).message }, { status: 500 });
        }
      },
    },
  },
});

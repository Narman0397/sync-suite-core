// Pembersihan otomatis foto selfie absensi berusia > 7 hari.
// Dipanggil penjadwal (cron). Wajib menyertakan header rahasia.
import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/api/public/cleanup-absensi-foto")({
  server: {
    handlers: {
      POST: async ({ request }) => {
        const secret = process.env["CLEANUP_CRON_SECRET"] ?? process.env["CRON_SECRET"] ?? "";
        const given = request.headers.get("x-cron-secret") ?? "";
        if (!secret || given !== secret) return new Response("Unauthorized", { status: 401 });
        const { purgeExpiredAbsensiFoto } = await import("@/lib/asn-face.server");
        try {
          const res = await purgeExpiredAbsensiFoto();
          return Response.json({ ok: true, ...res });
        } catch (e) {
          return Response.json({ ok: false, error: (e as Error).message }, { status: 500 });
        }
      },
    },
  },
});

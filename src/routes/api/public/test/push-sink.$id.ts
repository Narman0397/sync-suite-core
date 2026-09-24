// Sink endpoint yang mensimulasikan push service (FCM/Mozilla) untuk E2E test.
// Menerima POST web-push dari worker itu sendiri, menyimpan raw body + headers
// ke `push_test_sink`. Gated: sub id harus terdaftar di `push_test_sub`.
import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/api/public/test/push-sink/$id")({
  server: {
    handlers: {
      POST: async ({ request, params }) => {
        const subId = params.id;
        if (!/^[0-9a-f-]{36}$/i.test(subId)) return new Response("bad id", { status: 400 });
        const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
        const { data: sub } = await supabaseAdmin
          .from("push_test_sub")
          .select("id")
          .eq("id", subId)
          .maybeSingle();
        if (!sub) return new Response("not found", { status: 404 });

        const bodyBuf = new Uint8Array(await request.arrayBuffer());
        let bin = "";
        for (const x of bodyBuf) bin += String.fromCharCode(x);
        const body_b64 = btoa(bin);
        const headers: Record<string, string> = {};
        request.headers.forEach((v, k) => {
          headers[k.toLowerCase()] = v;
        });

        await supabaseAdmin.from("push_test_sink").insert({
          sub_id: subId,
          headers: headers as never,
          body_b64,
        });
        return new Response("ok", { status: 201 });
      },
    },
  },
});

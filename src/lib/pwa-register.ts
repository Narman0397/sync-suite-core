// Wrapper registrasi PWA SW.
// - Aktif di build development langsung dan production/published.
// - Jangan register di iframe/editor embed atau koneksi non-secure.
// - Hormati ?sw=off untuk men-unregister SW jika debugging.
export function registerPWA() {
  if (typeof window === "undefined") return;
  if (!("serviceWorker" in navigator)) return;

  const inIframe = (() => {
    try {
      return window.self !== window.top;
    } catch {
      return true;
    }
  })();
  const host = window.location.hostname;
  const localHost = host === "localhost" || host === "127.0.0.1" || host === "0.0.0.0";
  const secureContext = window.isSecureContext || localHost;
  const editorHost =
    host === "lovableproject.com" ||
    host.endsWith(".lovableproject.com") ||
    host === "lovableproject-dev.com" ||
    host.endsWith(".lovableproject-dev.com") ||
    host === "beta.lovable.dev" ||
    host.endsWith(".beta.lovable.dev") ||
    // Preview Lovable (id-preview--*.lovable.app dsb): jangan pasang SW supaya
    // preview selalu menampilkan build terbaru.
    host.startsWith("id-preview--") ||
    host.endsWith("-dev.lovable.app");
  const swOff = new URL(window.location.href).searchParams.get("sw") === "off";

  const blocked = !secureContext || inIframe || editorHost || swOff;

  if (blocked) {
    // Bersihkan registrasi yang mungkin sudah terpasang dari kunjungan sebelumnya
    // (mis. pengguna yang sebelumnya membuka URL produksi lalu kembali ke preview).
    navigator.serviceWorker
      .getRegistrations()
      .then((regs) => {
        regs.forEach((r) => {
          const u = r.active?.scriptURL || "";
          if (u.endsWith("/sw.js") || u.endsWith("/service-worker.js")) r.unregister();
        });
      })
      .catch(() => {});
    return;
  }

  // Jangan mendaftarkan /service-worker.js di sini: path itu adalah kill-switch
  // lama dengan scope yang sama dan dapat mengganti lalu melepas SW utama.
  const swUrl = import.meta.env.DEV ? "/dev-sw.js?dev-sw" : "/sw.js";
  const options: RegistrationOptions = import.meta.env.DEV
    ? { scope: "/", type: "module" }
    : { scope: "/" };

  navigator.serviceWorker
    .register(swUrl, options)
    .then((registration) => {
      registration.update().catch(() => {});
    })
    .catch(() => {});
}

// Auto-aktif notifikasi PWA. Berjalan di mode standalone (PWA terinstal)
// dan juga ketika izin notifikasi sudah granted di browser biasa.
// Mendengarkan pesan dari service worker untuk menampilkan toast saat foreground.
import { memo, useCallback, useEffect } from "react";
import { useServerFn } from "@tanstack/react-start";
import { toast } from "sonner";
import {
  getPushRuntimeConfig,
  registerPushSubscription,
  type RegisterPushSubscriptionInput,
} from "@/lib/push/subscription.functions";

// Fallback public VAPID key untuk kompatibilitas clone lama. Nilai utama diambil
// dari backend runtime agar selalu sinkron dengan private key Cloudflare/Lovable Cloud.
export const LEGACY_VAPID_PUBLIC_KEY =
  "BKdt7iJl_ShzVJ_HyUEzfXZVoofdWTcNWhUoq0gQQUyw_0cwbbbJzbrXUcDhQgXmoKgot8beQYCfsRoUsCVc6_c";

export type PushEnsureStatus = "ok" | "denied" | "unsupported" | "iframe" | "error";

export type PushEnsureResult = {
  status: PushEnsureStatus;
  detail: string;
  code?: string;
  endpoint?: string;
};

type EnsureSubscriptionOptions = {
  getVapidPublicKey: () => Promise<string>;
  saveSubscription: (subscription: RegisterPushSubscriptionInput) => Promise<unknown>;
};

function urlBase64ToUint8Array(base64String: string) {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const raw = atob(base64);
  const arr = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) arr[i] = raw.charCodeAt(i);
  return arr;
}

function toArrayBuffer(bytes: Uint8Array): ArrayBuffer {
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
}

function keyToBytes(key: unknown): Uint8Array | null {
  if (!key) return null;
  if (typeof key === "string") return urlBase64ToUint8Array(key);
  if (key instanceof ArrayBuffer) return new Uint8Array(key);
  if (ArrayBuffer.isView(key)) {
    return new Uint8Array(
      key.buffer.slice(key.byteOffset, key.byteOffset + key.byteLength) as ArrayBuffer,
    );
  }
  return null;
}

function isPreviewOrIframe() {
  if (typeof window === "undefined") return true;
  try {
    if (window.self !== window.top) return true;
  } catch {
    return true;
  }
  const h = window.location.hostname;
  return h.includes("id-preview--") || h.includes("lovableproject.com");
}

function errorMessage(error: unknown) {
  if (error instanceof Error) return `${error.name}: ${error.message}`;
  return String(error || "Unknown error");
}

async function waitForActiveRegistration(reg: ServiceWorkerRegistration) {
  if (reg.active) return reg;
  const worker = reg.installing || reg.waiting;
  if (worker) {
    await new Promise<void>((resolve) => {
      const done = () => {
        if (worker.state === "activated") {
          worker.removeEventListener("statechange", done);
          resolve();
        }
      };
      worker.addEventListener("statechange", done);
      done();
      setTimeout(resolve, 5000);
    });
  }
  return navigator.serviceWorker.ready;
}

async function getPushServiceWorkerRegistration() {
  const expectedUrl = import.meta.env.DEV ? "/dev-sw.js?dev-sw" : "/sw.js";
  const options: RegistrationOptions = import.meta.env.DEV
    ? { scope: "/", type: "module" }
    : { scope: "/" };
  let reg = await navigator.serviceWorker.getRegistration("/");
  const activeUrl = reg?.active?.scriptURL || reg?.waiting?.scriptURL || reg?.installing?.scriptURL || "";
  const staleKillSwitch = activeUrl.endsWith("/service-worker.js");
  const wrongDevWorker = import.meta.env.DEV && activeUrl && !activeUrl.includes("dev-sw.js");
  const wrongProdWorker = import.meta.env.PROD && activeUrl && !activeUrl.endsWith("/sw.js");

  if (reg && (staleKillSwitch || wrongDevWorker || wrongProdWorker)) {
    await reg.unregister().catch(() => false);
    reg = undefined;
  }
  if (!reg) reg = await navigator.serviceWorker.register(expectedUrl, options);
  await reg.update().catch(() => {});
  return waitForActiveRegistration(reg);
}

async function bufToB64(buf: ArrayBuffer | null) {
  if (!buf) return "";
  const bytes = new Uint8Array(buf);
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export async function ensureSubscription(
  userId: string,
  options: EnsureSubscriptionOptions,
): Promise<PushEnsureResult> {
  if (!userId) return { status: "error", code: "missing-user", detail: "User belum terdeteksi." };
  if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
    return {
      status: "unsupported",
      code: "api-unsupported",
      detail: "Browser tidak mendukung Service Worker atau Push API.",
    };
  }
  if (!("Notification" in window)) {
    return {
      status: "unsupported",
      code: "notification-unsupported",
      detail: "Browser tidak mendukung Notification API.",
    };
  }
  if (!window.isSecureContext) {
    return {
      status: "unsupported",
      code: "insecure-context",
      detail: "Notifikasi push membutuhkan HTTPS atau localhost.",
    };
  }
  // Push API tidak bekerja di iframe cross-origin (mis. preview editor Lovable).
  // Deteksi & laporkan agar UI dapat memberi instruksi buka tab baru.
  try {
    if (window.self !== window.top) {
      return {
        status: "iframe",
        code: "iframe",
        detail: "Notifikasi push tidak bisa aktif di dalam preview editor. Buka URL aplikasi langsung.",
      };
    }
  } catch {
    return {
      status: "iframe",
      code: "iframe",
      detail: "Notifikasi push tidak bisa aktif di dalam preview editor. Buka URL aplikasi langsung.",
    };
  }
  if (Notification.permission === "denied") {
    return {
      status: "denied",
      code: "permission-denied",
      detail: "Izin notifikasi ditolak browser. Ubah izin situs menjadi Izinkan lalu coba lagi.",
    };
  }


  // Minta izin SEBELUM register SW — beberapa browser (Safari/iOS) mensyaratkan
  // requestPermission dipanggil sinkron dari user gesture, sebelum await panjang.
  if (Notification.permission === "default") {
    let res: NotificationPermission;
    try {
      res = await Notification.requestPermission();
    } catch (e) {
      return {
        status: "error",
        code: "permission-request-failed",
        detail: `Gagal meminta izin notifikasi: ${errorMessage(e)}`,
      };
    }
    if (res !== "granted") {
      return {
        status: "denied",
        code: "permission-not-granted",
        detail: "Izin notifikasi belum diberikan oleh browser.",
      };
    }
  }

  let reg: ServiceWorkerRegistration;
  try {
    reg = await getPushServiceWorkerRegistration();
  } catch (e) {
    console.error("[push] gagal register service worker", e);
    return {
      status: "error",
      code: "sw-register-failed",
      detail: `Gagal mendaftarkan service worker: ${errorMessage(e)}`,
    };
  }

  let vapidPublicKey = LEGACY_VAPID_PUBLIC_KEY;
  try {
    vapidPublicKey = (await options.getVapidPublicKey()) || LEGACY_VAPID_PUBLIC_KEY;
  } catch (e) {
    console.error("[push] gagal ambil VAPID public key", e);
    return {
      status: "error",
      code: "vapid-config-failed",
      detail: `Gagal mengambil konfigurasi push: ${errorMessage(e)}`,
    };
  }

  let desiredKey: Uint8Array;
  try {
    desiredKey = urlBase64ToUint8Array(vapidPublicKey);
  } catch (e) {
    return {
      status: "error",
      code: "invalid-vapid-public-key",
      detail: `Public key notifikasi tidak valid: ${errorMessage(e)}`,
    };
  }

  let sub: PushSubscription | null;
  try {
    sub = await reg.pushManager.getSubscription();
  } catch (e) {
    console.error("[push] gagal membaca subscription", e);
    return {
      status: "error",
      code: "get-subscription-failed",
      detail: `Gagal membaca subscription browser: ${errorMessage(e)}`,
    };
  }

  // Jika subscription lama dibuat dengan public key berbeda → unsubscribe & buat ulang.
  if (sub) {
    const existingKey = sub.options?.applicationServerKey;
    const bytes = keyToBytes(existingKey);
    const matches =
      bytes &&
      bytes.length === desiredKey.length &&
      bytes.every((v, i) => v === desiredKey[i]);
    if (!matches) {
      try {
        await sub.unsubscribe();
      } catch (e) {
        console.warn("[push] gagal unsubscribe subscription lama", e);
      }
      sub = null;
    }
  }

  if (!sub) {
    try {
      sub = await reg.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: toArrayBuffer(desiredKey),
      });
    } catch (e) {
      console.error("[push] gagal subscribe pushManager", e);
      return {
        status: "error",
        code: "push-subscribe-failed",
        detail: `Browser gagal membuat subscription push: ${errorMessage(e)}`,
      };
    }
  }

  const json = sub.toJSON();
  const endpoint = json.endpoint!;
  const p256dh = json.keys?.p256dh || (await bufToB64(sub.getKey("p256dh")));
  const auth = json.keys?.auth || (await bufToB64(sub.getKey("auth")));

  try {
    await options.saveSubscription({ endpoint, p256dh, auth, userAgent: navigator.userAgent });
  } catch (e) {
    console.error("[push] gagal simpan subscription ke server", e);
    return {
      status: "error",
      code: "save-subscription-failed",
      detail: `Gagal menyimpan perangkat ke backend: ${errorMessage(e)}`,
    };
  }
  return { status: "ok", detail: "Perangkat terdaftar untuk notifikasi push.", endpoint };
}

import { useAuthUser } from "@/lib/auth-context";

function PushAutoEnableImpl() {
  const { user } = useAuthUser();
  const userId = user?.id;
  const getConfigFn = useServerFn(getPushRuntimeConfig);
  const registerFn = useServerFn(registerPushSubscription);

  const getVapidPublicKey = useCallback(async () => {
    const config = (await getConfigFn()) as { vapidPublicKey?: string };
    return config.vapidPublicKey || LEGACY_VAPID_PUBLIC_KEY;
  }, [getConfigFn]);

  const saveSubscription = useCallback(
    (subscription: RegisterPushSubscriptionInput) => registerFn({ data: subscription }),
    [registerFn],
  );

  // Foreground toast dari SW.
  useEffect(() => {
    if (typeof navigator === "undefined" || !("serviceWorker" in navigator)) return;
    const onMsg = (e: MessageEvent) => {
      const d = e.data;
      if (d?.type === "push") {
        toast(d.title || "Notifikasi", { description: d.body });
      }
    };
    navigator.serviceWorker.addEventListener("message", onMsg);
    return () => navigator.serviceWorker.removeEventListener("message", onMsg);
  }, []);

  useEffect(() => {
    if (!userId) return;
    if (isPreviewOrIframe()) return;
    if (typeof Notification === "undefined") return;
    // Kalau user sudah menolak izin, jangan coba lagi (browser tak akan menampilkan prompt).
    if (Notification.permission === "denied") return;

    // Guard per-user per-sesi supaya prompt izin tidak muncul berulang bila
    // user menutup dialog / navigasi antar halaman.
    const guardKey = `push:auto:${userId}`;
    const tryEnable = () => {
      try {
        if (sessionStorage.getItem(guardKey) === "done") return;
      } catch {
        /* ignore */
      }
      ensureSubscription(userId, { getVapidPublicKey, saveSubscription })
        .then((res) => {
          if (res.status === "ok" || res.status === "denied") {
            try {
              sessionStorage.setItem(guardKey, "done");
            } catch {
              /* ignore */
            }
          }
        })
        .catch(() => {});
    };
    tryEnable();
    window.addEventListener("appinstalled", tryEnable);
    return () => window.removeEventListener("appinstalled", tryEnable);
  }, [getVapidPublicKey, saveSubscription, userId]);

  return null;
}

export const PushAutoEnable = memo(PushAutoEnableImpl);


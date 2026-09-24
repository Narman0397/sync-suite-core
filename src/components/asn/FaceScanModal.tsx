// Tampilan proses pemindaian wajah saat absensi ASN.
// Menampilkan kamera depan secara langsung, bingkai pemandu wajah, animasi garis
// pemindai, hitung mundur, lalu mengembalikan foto (data URL JPEG) ke pemanggil.
import { useCallback, useEffect, useRef, useState } from "react";
import { Loader2, ScanFace, X } from "lucide-react";

type Phase = "starting" | "ready" | "counting" | "captured" | "verifying" | "error";

export function FaceScanModal({
  open,
  title = "Verifikasi Wajah",
  subtitle,
  busy,
  onCapture,
  onCancel,
}: {
  open: boolean;
  title?: string;
  subtitle?: string;
  /** true saat server sedang memproses hasil (kirim absen / cocokkan wajah) */
  busy?: boolean;
  onCapture: (dataUrl: string) => void | Promise<void>;
  onCancel: () => void;
}) {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const [phase, setPhase] = useState<Phase>("starting");
  const [err, setErr] = useState<string | null>(null);
  const [count, setCount] = useState(3);
  const [shot, setShot] = useState<string | null>(null);

  const stop = useCallback(() => {
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;
  }, []);

  useEffect(() => {
    if (!open) return;
    let cancelled = false;
    setPhase("starting");
    setErr(null);
    setShot(null);
    setCount(3);
    (async () => {
      try {
        const s = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: "user", width: { ideal: 640 } },
          audio: false,
        });
        if (cancelled) {
          s.getTracks().forEach((t) => t.stop());
          return;
        }
        streamRef.current = s;
        if (videoRef.current) {
          videoRef.current.srcObject = s;
          await videoRef.current.play();
        }
        setPhase("ready");
      } catch {
        setErr("Kamera tidak dapat diakses. Berikan izin kamera pada peramban Anda.");
        setPhase("error");
      }
    })();
    return () => {
      cancelled = true;
      stop();
    };
  }, [open, stop]);

  const grabFrame = useCallback((): string | null => {
    const video = videoRef.current;
    if (!video) return null;
    const w = Math.min(640, video.videoWidth || 640);
    const h = Math.round((video.videoHeight || 480) * (w / (video.videoWidth || 640)));
    const canvas = document.createElement("canvas");
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext("2d");
    if (!ctx) return null;
    ctx.drawImage(video, 0, 0, w, h);
    return canvas.toDataURL("image/jpeg", 0.8);
  }, []);

  // Hitung mundur sebelum foto diambil.
  useEffect(() => {
    if (phase !== "counting") return;
    if (count <= 0) {
      const data = grabFrame();
      if (!data) {
        setErr("Gagal mengambil gambar dari kamera.");
        setPhase("error");
        return;
      }
      setShot(data);
      setPhase("captured");
      stop();
      setPhase("verifying");
      void onCapture(data);
      return;
    }
    const t = setTimeout(() => setCount((c) => c - 1), 900);
    return () => clearTimeout(t);
  }, [phase, count, grabFrame, onCapture, stop]);

  if (!open) return null;

  const scanning = phase === "counting";
  const verifying = phase === "verifying" || !!busy;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/70 p-0 sm:items-center sm:p-4">
      <div className="w-full max-w-md rounded-t-2xl border border-border bg-card p-4 sm:rounded-2xl">
        <div className="flex items-start justify-between gap-2">
          <div>
            <div className="font-display text-base font-bold">{title}</div>
            <div className="text-xs text-muted-foreground">
              {subtitle ?? "Posisikan wajah Anda di dalam bingkai"}
            </div>
          </div>
          <button
            onClick={() => {
              stop();
              onCancel();
            }}
            disabled={verifying}
            aria-label="Tutup"
            className="rounded p-1 text-muted-foreground hover:text-foreground disabled:opacity-40"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {phase === "error" ? (
          <div className="mt-4 rounded-lg border border-destructive/40 bg-destructive/10 p-3 text-sm text-destructive">
            {err}
          </div>
        ) : (
          <>
            <div className="relative mt-3 overflow-hidden rounded-xl bg-black">
              {shot ? (
                <img
                  src={shot}
                  alt="Hasil pemindaian wajah"
                  className="aspect-[4/3] w-full scale-x-[-1] object-cover"
                />
              ) : (
                <video
                  ref={videoRef}
                  playsInline
                  muted
                  className="aspect-[4/3] w-full scale-x-[-1] object-cover"
                />
              )}

              {/* Bingkai pemandu wajah */}
              <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
                <div
                  className={`h-[78%] w-[58%] rounded-[50%] border-2 transition-colors ${
                    verifying
                      ? "border-success animate-pulse"
                      : scanning
                        ? "border-primary animate-pulse"
                        : "border-white/70"
                  }`}
                />
              </div>

              {/* Garis pemindai */}
              {(scanning || verifying) && (
                <div className="pointer-events-none absolute inset-x-0 top-0 h-full overflow-hidden">
                  <div className="face-scan-line h-0.5 w-full bg-primary/90 shadow-[0_0_12px_2px_hsl(var(--primary))]" />
                </div>
              )}

              {phase === "starting" && (
                <div className="absolute inset-0 flex items-center justify-center text-xs text-white/80">
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" /> Menyalakan kamera…
                </div>
              )}

              {scanning && count > 0 && (
                <div className="absolute inset-0 flex items-center justify-center">
                  <span className="font-display text-6xl font-bold text-white drop-shadow-lg">
                    {count}
                  </span>
                </div>
              )}

              {verifying && (
                <div className="absolute inset-x-0 bottom-0 bg-black/60 px-3 py-2 text-center text-xs font-semibold text-white">
                  <Loader2 className="mr-2 inline h-3.5 w-3.5 animate-spin" />
                  Mencocokkan wajah Anda…
                </div>
              )}
            </div>

            <p className="mt-3 text-xs text-muted-foreground">
              {verifying
                ? "Mohon tunggu, wajah Anda sedang diverifikasi."
                : scanning
                  ? "Tahan posisi, wajah sedang dipindai."
                  : "Pastikan pencahayaan cukup, lepas masker, dan tatap kamera."}
            </p>

            <div className="mt-3 flex gap-2">
              <button
                disabled={phase !== "ready"}
                onClick={() => {
                  setCount(3);
                  setPhase("counting");
                }}
                className="inline-flex h-11 flex-1 items-center justify-center rounded-md bg-gradient-primary px-4 text-sm font-semibold text-primary-foreground disabled:opacity-60"
              >
                <ScanFace className="mr-2 h-4 w-4" />
                {phase === "ready" ? "Mulai Pindai Wajah" : "Memproses…"}
              </button>
              <button
                onClick={() => {
                  stop();
                  onCancel();
                }}
                disabled={verifying}
                className="h-11 rounded-md border border-border px-4 text-sm disabled:opacity-40"
              >
                Batal
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

// Pengambilan foto wajah dari kamera perangkat (dipakai admin saat merekam wajah ASN).
import { useCallback, useEffect, useRef, useState } from "react";
import { Camera, Loader2, X } from "lucide-react";

export type FacePose = { key: string; label: string };

export const FACE_POSES: FacePose[] = [
  { key: "depan", label: "Tampak depan" },
  { key: "kiri", label: "Serong kiri" },
  { key: "kanan", label: "Serong kanan" },
];

export function FaceCapture({
  onDone,
  onCancel,
  busy,
  nama,
}: {
  onDone: (photos: string[]) => void | Promise<void>;
  onCancel: () => void;
  busy: boolean;
  nama: string;
}) {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const [ready, setReady] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [shots, setShots] = useState<string[]>([]);

  useEffect(() => {
    let cancelled = false;
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
        setReady(true);
      } catch {
        setErr("Kamera tidak dapat diakses. Berikan izin kamera pada peramban.");
      }
    })();
    return () => {
      cancelled = true;
      streamRef.current?.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
    };
  }, []);

  const ambil = useCallback(() => {
    const video = videoRef.current;
    if (!video) return;
    const w = Math.min(640, video.videoWidth || 640);
    const h = Math.round((video.videoHeight || 480) * (w / (video.videoWidth || 640)));
    const canvas = document.createElement("canvas");
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.drawImage(video, 0, 0, w, h);
    setShots((s) => [...s, canvas.toDataURL("image/jpeg", 0.85)]);
  }, []);

  const pose = FACE_POSES[shots.length];

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 p-0 sm:items-center sm:p-4">
      <div className="w-full max-w-md rounded-t-2xl border border-border bg-card p-4 sm:rounded-2xl">
        <div className="flex items-start justify-between gap-2">
          <div>
            <div className="font-display text-base font-bold">Rekam Wajah</div>
            <div className="text-xs text-muted-foreground">{nama}</div>
          </div>
          <button
            onClick={onCancel}
            aria-label="Tutup"
            className="rounded p-1 text-muted-foreground hover:text-foreground"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {err ? (
          <div className="mt-4 rounded-lg border border-destructive/40 p-3 text-sm text-destructive">
            {err}
          </div>
        ) : (
          <>
            <div className="relative mt-3 overflow-hidden rounded-xl bg-black">
              <video
                ref={videoRef}
                playsInline
                muted
                className="aspect-[4/3] w-full scale-x-[-1] object-cover"
              />
              {!ready && (
                <div className="absolute inset-0 flex items-center justify-center text-xs text-white/80">
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" /> Menyalakan kamera…
                </div>
              )}
            </div>

            <div className="mt-3 flex items-center gap-2">
              {FACE_POSES.map((p, i) => (
                <span
                  key={p.key}
                  className={`flex-1 rounded-md px-2 py-1 text-center text-[11px] font-semibold ${
                    i < shots.length
                      ? "bg-success/15 text-success"
                      : i === shots.length
                        ? "bg-primary/15 text-primary"
                        : "bg-muted text-muted-foreground"
                  }`}
                >
                  {p.label}
                </span>
              ))}
            </div>

            <div className="mt-3 flex gap-2">
              {pose ? (
                <button
                  onClick={ambil}
                  disabled={!ready || busy}
                  className="inline-flex h-10 flex-1 items-center justify-center gap-2 rounded-md bg-gradient-primary px-4 text-sm font-semibold text-primary-foreground disabled:opacity-60"
                >
                  <Camera className="h-4 w-4" /> Ambil {pose.label.toLowerCase()}
                </button>
              ) : (
                <button
                  onClick={() => void onDone(shots)}
                  disabled={busy}
                  className="inline-flex h-10 flex-1 items-center justify-center gap-2 rounded-md bg-gradient-primary px-4 text-sm font-semibold text-primary-foreground disabled:opacity-60"
                >
                  {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : null} Simpan rekaman wajah
                </button>
              )}
              {shots.length > 0 && !busy && (
                <button
                  onClick={() => setShots([])}
                  className="h-10 rounded-md border border-border px-3 text-sm"
                >
                  Ulangi
                </button>
              )}
            </div>
            <p className="mt-2 text-[11px] text-muted-foreground">
              Pastikan wajah ASN terlihat jelas, pencahayaan cukup, dan latar belakang sama untuk
              ketiga foto.
            </p>
          </>
        )}
      </div>
    </div>
  );
}

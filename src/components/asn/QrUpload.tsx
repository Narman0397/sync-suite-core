// Opsi alternatif: unggah gambar QR kantor (untuk pengujian / kamera tidak tersedia).
import { useRef, useState } from "react";
import { Upload } from "lucide-react";
import { toast } from "sonner";

export function QrUpload({ onResult }: { onResult: (text: string) => void }) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const hostId = useRef(`qr-file-${Math.random().toString(36).slice(2, 8)}`);

  const onFile = async (file: File | undefined) => {
    if (!file) return;
    setBusy(true);
    try {
      const mod = await import("html5-qrcode");
      const reader = new mod.Html5Qrcode(hostId.current);
      try {
        const text = await reader.scanFile(file, false);
        onResult(text);
      } finally {
        try {
          reader.clear();
        } catch {
          /* noop */
        }
      }
    } catch {
      toast.error("QR tidak terbaca dari gambar. Pastikan gambar jelas dan berisi QR kantor.");
    } finally {
      setBusy(false);
      if (inputRef.current) inputRef.current.value = "";
    }
  };

  return (
    <div className="mt-3">
      <div id={hostId.current} className="hidden" />
      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(e) => onFile(e.target.files?.[0])}
      />
      <button
        type="button"
        disabled={busy}
        onClick={() => inputRef.current?.click()}
        className="inline-flex h-10 w-full items-center justify-center gap-2 rounded-md border border-border bg-card px-4 text-sm font-semibold text-foreground disabled:opacity-60"
      >
        <Upload className="h-4 w-4" />
        {busy ? "Membaca QR…" : "Upload Gambar QR"}
      </button>
    </div>
  );
}

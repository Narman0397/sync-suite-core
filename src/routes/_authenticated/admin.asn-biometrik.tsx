// Perekaman sidik jari ASN oleh Admin OPD (ASN di OPD-nya) & Super Admin.
import { useCallback, useEffect, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { startRegistration } from "@simplewebauthn/browser";
import { Fingerprint, Loader2, Trash2 } from "lucide-react";
import { AdminShell } from "@/components/admin/AdminShell";
import { AdminGuard } from "@/components/admin/AdminGuard";
import {
  adminListAsnBiometric,
  adminStartBiometricRegistration,
  adminFinishBiometricRegistration,
  adminDeleteBiometricCredential,
} from "@/lib/asn-biometric.functions";

export const Route = createFileRoute("/_authenticated/admin/asn-biometrik")({
  head: () => ({
    meta: [
      { title: "Perekaman Sidik Jari ASN — Admin" },
      { name: "description", content: "Rekam minimal 3 sidik jari ASN untuk verifikasi absensi." },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: () => (
    <AdminGuard>
      <Page />
    </AdminGuard>
  ),
});

const FINGERS = [
  "Jempol kanan",
  "Telunjuk kanan",
  "Tengah kanan",
  "Jempol kiri",
  "Telunjuk kiri",
  "Tengah kiri",
];

type Finger = { id: string; finger_label: string | null; device_label: string | null; created_at: string };
type Row = { id: string; nama_lengkap: string | null; nip: string | null; fingers: Finger[] };

function deviceLabel() {
  const ua = navigator.userAgent;
  if (/iPhone|iPad/i.test(ua)) return "iPhone / iPad";
  if (/Android/i.test(ua)) return "Android";
  if (/Mac OS X/i.test(ua)) return "Mac (Touch ID)";
  if (/Windows/i.test(ua)) return "Windows Hello";
  return "Perangkat kantor";
}

function Page() {
  const [rows, setRows] = useState<Row[]>([]);
  const [min, setMin] = useState(3);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [q, setQ] = useState("");

  const reload = useCallback(async () => {
    try {
      const r = (await adminListAsnBiometric()) as unknown as { rows: Row[]; min: number };
      setRows(r.rows);
      setMin(r.min);
      setErr(null);
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, []);
  useEffect(() => {
    void reload();
  }, [reload]);

  const rekam = async (row: Row, finger: string) => {
    setBusy(row.id);
    try {
      const { options } = (await adminStartBiometricRegistration({
        data: { target_user_id: row.id },
      })) as unknown as { options: Parameters<typeof startRegistration>[0]["optionsJSON"] };
      toast.info(`Minta ${row.nama_lengkap ?? "ASN"} menempelkan ${finger.toLowerCase()} ke sensor…`);
      const att = await startRegistration({ optionsJSON: options });
      await adminFinishBiometricRegistration({
        data: {
          target_user_id: row.id,
          response: att as unknown as Record<string, unknown>,
          finger_label: finger,
          device_label: deviceLabel(),
        },
      });
      toast.success(`${finger} tersimpan.`);
      await reload();
    } catch (e) {
      toast.error((e as Error).message || "Perekaman dibatalkan.");
    } finally {
      setBusy(null);
    }
  };

  const hapus = async (row: Row, id: string) => {
    setBusy(row.id);
    try {
      await adminDeleteBiometricCredential({ data: { target_user_id: row.id, id } });
      toast.success("Rekaman jari dihapus.");
      await reload();
    } catch (e) {
      toast.error((e as Error).message);
    } finally {
      setBusy(null);
    }
  };

  const filtered = rows.filter((r) =>
    `${r.nama_lengkap ?? ""} ${r.nip ?? ""}`.toLowerCase().includes(q.toLowerCase()),
  );

  return (
    <AdminShell breadcrumb={[{ label: "Sidik Jari ASN" }]}>
      <h1 className="font-display text-2xl font-bold">Perekaman Sidik Jari ASN</h1>
      <p className="mt-1 max-w-3xl text-sm text-muted-foreground">
        Rekam minimal {min} jari per ASN memakai sensor sidik jari perangkat ini, dengan ASN hadir
        langsung. Kunci verifikasi disimpan di server; verifikasi saat absen baru berlaku setelah{" "}
        {min} jari terekam.
      </p>
      <input
        value={q}
        onChange={(e) => setQ(e.target.value)}
        placeholder="Cari nama atau NIP…"
        className="mt-4 h-9 w-full max-w-sm rounded-md border border-border bg-background px-3 text-sm"
      />

      {loading ? (
        <div className="mt-6 flex items-center gap-2 text-sm text-muted-foreground">
          <Loader2 className="h-4 w-4 animate-spin" /> Memuat…
        </div>
      ) : err ? (
        <div className="mt-6 rounded-lg border border-destructive/40 p-4 text-sm text-destructive">
          {err}
        </div>
      ) : filtered.length === 0 ? (
        <div className="mt-6 rounded-lg border border-border p-8 text-center text-sm text-muted-foreground">
          Belum ada ASN di cakupan Anda.
        </div>
      ) : (
        <div className="mt-4 grid gap-3 md:grid-cols-2">
          {filtered.map((r) => {
            const used = new Set(r.fingers.map((f) => f.finger_label));
            const done = r.fingers.length >= min;
            return (
              <div key={r.id} className="rounded-xl border border-border bg-card p-4">
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <div className="font-semibold">{r.nama_lengkap ?? "Tanpa nama"}</div>
                    <div className="text-xs text-muted-foreground tabular-nums">
                      NIP {r.nip ?? "—"}
                    </div>
                  </div>
                  <span
                    className={`rounded-full px-2 py-0.5 text-[11px] font-semibold tabular-nums ${done ? "bg-success/15 text-success" : "bg-muted text-muted-foreground"}`}
                  >
                    {r.fingers.length}/{min} jari
                  </span>
                </div>
                {r.fingers.length > 0 && (
                  <ul className="mt-3 space-y-1">
                    {r.fingers.map((f) => (
                      <li key={f.id} className="flex items-center justify-between text-xs">
                        <span>
                          {f.finger_label ?? "Jari"}
                          <span className="text-muted-foreground"> · {f.device_label ?? "—"}</span>
                        </span>
                        <button
                          onClick={() => hapus(r, f.id)}
                          disabled={busy === r.id}
                          aria-label="Hapus rekaman jari"
                          className="rounded p-1 text-muted-foreground hover:text-destructive disabled:opacity-50"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </li>
                    ))}
                  </ul>
                )}
                <div className="mt-3 flex flex-wrap gap-1.5">
                  {FINGERS.filter((f) => !used.has(f)).map((f) => (
                    <button
                      key={f}
                      onClick={() => rekam(r, f)}
                      disabled={busy !== null}
                      className="inline-flex h-8 items-center gap-1 rounded-md border border-border px-2 text-[11px] font-medium hover:bg-muted disabled:opacity-50"
                    >
                      <Fingerprint className="h-3.5 w-3.5" /> {f}
                    </button>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </AdminShell>
  );
}

// Perekaman biometrik ASN oleh Admin OPD (ASN di OPD-nya) & Super Admin:
// sidik jari (WebAuthn), wajah (server-side), serta penugasan Work From Anywhere.
import { useCallback, useEffect, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { startRegistration } from "@simplewebauthn/browser";
import { Fingerprint, Loader2, ScanFace, Trash2, MapPinned } from "lucide-react";
import { AdminShell } from "@/components/admin/AdminShell";
import { AdminGuard } from "@/components/admin/AdminGuard";
import { FaceCapture } from "@/components/asn/FaceCapture";
import {
  adminListAsnBiometric,
  adminStartBiometricRegistration,
  adminFinishBiometricRegistration,
  adminDeleteBiometricCredential,
} from "@/lib/asn-biometric.functions";
import {
  adminListAsnFace,
  adminEnrollAsnFace,
  adminDeleteAsnFace,
  adminCreateWfa,
  adminDeleteWfa,
} from "@/lib/asn-face.functions";

export const Route = createFileRoute("/_authenticated/admin/asn-biometrik")({
  head: () => ({
    meta: [
      { title: "Biometrik & Penugasan ASN — Admin" },
      {
        name: "description",
        content:
          "Rekam sidik jari dan wajah ASN serta atur penugasan kerja dari luar kantor untuk absensi.",
      },
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

type Finger = {
  id: string;
  finger_label: string | null;
  device_label: string | null;
  created_at: string;
};
type Row = { id: string; nama_lengkap: string | null; nip: string | null; fingers: Finger[] };

type Face = {
  user_id: string;
  samples: number;
  quality: number | null;
  adapt_count: number;
  updated_at: string;
} | null;
type Wfa = {
  id: string;
  user_id: string;
  mulai: string;
  selesai: string;
  alasan: string | null;
  nomor_surat: string | null;
  status: string;
};
type FaceRow = {
  id: string;
  nama_lengkap: string | null;
  nip: string | null;
  face: Face;
  wfa: Wfa[];
};

function deviceLabel() {
  const ua = navigator.userAgent;
  if (/iPhone|iPad/i.test(ua)) return "iPhone / iPad";
  if (/Android/i.test(ua)) return "Android";
  if (/Mac OS X/i.test(ua)) return "Mac (Touch ID)";
  if (/Windows/i.test(ua)) return "Windows Hello";
  return "Perangkat kantor";
}

const TABS = [
  { key: "wajah", label: "Rekam Wajah" },
  { key: "wfa", label: "Penugasan Luar Kantor" },
  { key: "jari", label: "Sidik Jari" },
] as const;
type TabKey = (typeof TABS)[number]["key"];

function Page() {
  const [tab, setTab] = useState<TabKey>("wajah");
  const [rows, setRows] = useState<Row[]>([]);
  const [min, setMin] = useState(3);
  const [faceRows, setFaceRows] = useState<FaceRow[]>([]);
  const [faceMin, setFaceMin] = useState(3);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [q, setQ] = useState("");
  const [capture, setCapture] = useState<FaceRow | null>(null);
  const [wfaForm, setWfaForm] = useState<{
    user_id: string;
    mulai: string;
    selesai: string;
    alasan: string;
    nomor_surat: string;
  } | null>(null);

  const reload = useCallback(async () => {
    try {
      const [bio, face] = await Promise.all([
        adminListAsnBiometric() as unknown as Promise<{ rows: Row[]; min: number }>,
        adminListAsnFace() as unknown as Promise<{ rows: FaceRow[]; min: number }>,
      ]);
      setRows(bio.rows);
      setMin(bio.min);
      setFaceRows(face.rows);
      setFaceMin(face.min);
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

  const simpanWajah = async (photos: string[]) => {
    if (!capture) return;
    setBusy(capture.id);
    try {
      const r = (await adminEnrollAsnFace({
        data: { target_user_id: capture.id, photos },
      })) as unknown as { quality: number; samples: number };
      toast.success(`Wajah tersimpan (${r.samples} sampel, kualitas ${r.quality}).`);
      setCapture(null);
      await reload();
    } catch (e) {
      toast.error((e as Error).message);
    } finally {
      setBusy(null);
    }
  };

  const hapusWajah = async (row: FaceRow) => {
    setBusy(row.id);
    try {
      await adminDeleteAsnFace({ data: { target_user_id: row.id } });
      toast.success("Rekaman wajah dihapus.");
      await reload();
    } catch (e) {
      toast.error((e as Error).message);
    } finally {
      setBusy(null);
    }
  };

  const simpanWfa = async () => {
    if (!wfaForm) return;
    setBusy(wfaForm.user_id);
    try {
      await adminCreateWfa({
        data: {
          target_user_id: wfaForm.user_id,
          mulai: wfaForm.mulai,
          selesai: wfaForm.selesai,
          alasan: wfaForm.alasan || null,
          nomor_surat: wfaForm.nomor_surat || null,
        },
      });
      toast.success("Penugasan luar kantor tersimpan.");
      setWfaForm(null);
      await reload();
    } catch (e) {
      toast.error((e as Error).message);
    } finally {
      setBusy(null);
    }
  };

  const hapusWfa = async (row: FaceRow, id: string) => {
    setBusy(row.id);
    try {
      await adminDeleteWfa({ data: { target_user_id: row.id, id } });
      toast.success("Penugasan dibatalkan.");
      await reload();
    } catch (e) {
      toast.error((e as Error).message);
    } finally {
      setBusy(null);
    }
  };

  const match = (nama: string | null, nip: string | null) =>
    `${nama ?? ""} ${nip ?? ""}`.toLowerCase().includes(q.toLowerCase());
  const filtered = rows.filter((r) => match(r.nama_lengkap, r.nip));
  const filteredFace = faceRows.filter((r) => match(r.nama_lengkap, r.nip));
  const today = new Date().toISOString().slice(0, 10);

  return (
    <AdminShell breadcrumb={[{ label: "Biometrik & Penugasan ASN" }]}>
      <h1 className="font-display text-2xl font-bold">Biometrik &amp; Penugasan ASN</h1>
      <p className="mt-1 max-w-3xl text-sm text-muted-foreground">
        Rekam wajah ASN (minimal {faceMin} foto) untuk verifikasi absensi di server, atur penugasan
        kerja dari luar kantor, dan rekam sidik jari perangkat bila tersedia.
      </p>

      <div className="mt-4 inline-flex flex-wrap gap-1 rounded-lg border border-border bg-surface p-1">
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`h-9 rounded-md px-3 text-sm font-semibold ${
              tab === t.key ? "bg-gradient-primary text-primary-foreground" : "text-muted-foreground"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

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
      ) : tab === "jari" ? (
        filtered.length === 0 ? (
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
                            <span className="text-muted-foreground">
                              {" "}
                              · {f.device_label ?? "—"}
                            </span>
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
        )
      ) : filteredFace.length === 0 ? (
        <div className="mt-6 rounded-lg border border-border p-8 text-center text-sm text-muted-foreground">
          Belum ada ASN di cakupan Anda.
        </div>
      ) : (
        <div className="mt-4 grid gap-3 md:grid-cols-2">
          {filteredFace.map((r) => {
            const aktif = r.wfa.filter((w) => w.selesai >= today);
            return (
              <div key={r.id} className="rounded-xl border border-border bg-card p-4">
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <div className="font-semibold">{r.nama_lengkap ?? "Tanpa nama"}</div>
                    <div className="text-xs text-muted-foreground tabular-nums">
                      NIP {r.nip ?? "—"}
                    </div>
                  </div>
                  {tab === "wajah" ? (
                    <span
                      className={`rounded-full px-2 py-0.5 text-[11px] font-semibold ${r.face ? "bg-success/15 text-success" : "bg-muted text-muted-foreground"}`}
                    >
                      {r.face ? `${r.face.samples} sampel` : "Belum terekam"}
                    </span>
                  ) : (
                    <span
                      className={`rounded-full px-2 py-0.5 text-[11px] font-semibold ${aktif.length ? "bg-success/15 text-success" : "bg-muted text-muted-foreground"}`}
                    >
                      {aktif.length ? `${aktif.length} penugasan` : "Tidak ada"}
                    </span>
                  )}
                </div>

                {tab === "wajah" ? (
                  <>
                    {r.face && (
                      <div className="mt-2 text-xs text-muted-foreground">
                        Kualitas {r.face.quality ?? "—"} · penyesuaian {r.face.adapt_count}x ·
                        diperbarui {new Date(r.face.updated_at).toLocaleDateString("id-ID")}
                      </div>
                    )}
                    <div className="mt-3 flex flex-wrap gap-2">
                      <button
                        onClick={() => setCapture(r)}
                        disabled={busy !== null}
                        className="inline-flex h-9 items-center gap-1.5 rounded-md bg-gradient-primary px-3 text-xs font-semibold text-primary-foreground disabled:opacity-50"
                      >
                        <ScanFace className="h-4 w-4" /> {r.face ? "Rekam ulang" : "Rekam wajah"}
                      </button>
                      {r.face && (
                        <button
                          onClick={() => hapusWajah(r)}
                          disabled={busy !== null}
                          className="inline-flex h-9 items-center gap-1.5 rounded-md border border-border px-3 text-xs font-medium hover:bg-muted disabled:opacity-50"
                        >
                          <Trash2 className="h-3.5 w-3.5" /> Hapus
                        </button>
                      )}
                    </div>
                  </>
                ) : (
                  <>
                    {aktif.length > 0 && (
                      <ul className="mt-3 space-y-1">
                        {aktif.map((w) => (
                          <li key={w.id} className="flex items-start justify-between gap-2 text-xs">
                            <span>
                              {w.mulai} s.d. {w.selesai}
                              <span className="block text-muted-foreground">
                                {w.nomor_surat ? `${w.nomor_surat} · ` : ""}
                                {w.alasan ?? "Penugasan luar kantor"}
                              </span>
                            </span>
                            <button
                              onClick={() => hapusWfa(r, w.id)}
                              disabled={busy === r.id}
                              aria-label="Batalkan penugasan"
                              className="rounded p-1 text-muted-foreground hover:text-destructive disabled:opacity-50"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </button>
                          </li>
                        ))}
                      </ul>
                    )}
                    {wfaForm?.user_id === r.id ? (
                      <div className="mt-3 space-y-2">
                        <div className="flex gap-2">
                          <label className="flex-1 text-[11px] font-medium text-muted-foreground">
                            Mulai
                            <input
                              type="date"
                              value={wfaForm.mulai}
                              onChange={(e) =>
                                setWfaForm({ ...wfaForm, mulai: e.target.value })
                              }
                              className="mt-0.5 h-9 w-full rounded-md border border-border bg-background px-2 text-sm text-foreground"
                            />
                          </label>
                          <label className="flex-1 text-[11px] font-medium text-muted-foreground">
                            Selesai
                            <input
                              type="date"
                              value={wfaForm.selesai}
                              onChange={(e) =>
                                setWfaForm({ ...wfaForm, selesai: e.target.value })
                              }
                              className="mt-0.5 h-9 w-full rounded-md border border-border bg-background px-2 text-sm text-foreground"
                            />
                          </label>
                        </div>
                        <input
                          value={wfaForm.nomor_surat}
                          onChange={(e) =>
                            setWfaForm({ ...wfaForm, nomor_surat: e.target.value })
                          }
                          placeholder="Nomor surat tugas (opsional)"
                          className="h-9 w-full rounded-md border border-border bg-background px-2 text-sm"
                        />
                        <input
                          value={wfaForm.alasan}
                          onChange={(e) => setWfaForm({ ...wfaForm, alasan: e.target.value })}
                          placeholder="Keterangan tugas"
                          className="h-9 w-full rounded-md border border-border bg-background px-2 text-sm"
                        />
                        <div className="flex gap-2">
                          <button
                            onClick={simpanWfa}
                            disabled={busy !== null}
                            className="h-9 rounded-md bg-gradient-primary px-3 text-xs font-semibold text-primary-foreground disabled:opacity-50"
                          >
                            Simpan
                          </button>
                          <button
                            onClick={() => setWfaForm(null)}
                            className="h-9 rounded-md border border-border px-3 text-xs"
                          >
                            Batal
                          </button>
                        </div>
                      </div>
                    ) : (
                      <button
                        onClick={() =>
                          setWfaForm({
                            user_id: r.id,
                            mulai: today,
                            selesai: today,
                            alasan: "",
                            nomor_surat: "",
                          })
                        }
                        disabled={busy !== null}
                        className="mt-3 inline-flex h-9 items-center gap-1.5 rounded-md border border-border px-3 text-xs font-medium hover:bg-muted disabled:opacity-50"
                      >
                        <MapPinned className="h-4 w-4" /> Beri penugasan
                      </button>
                    )}
                  </>
                )}
              </div>
            );
          })}
        </div>
      )}

      {capture && (
        <FaceCapture
          nama={capture.nama_lengkap ?? "ASN"}
          busy={busy !== null}
          onCancel={() => setCapture(null)}
          onDone={simpanWajah}
        />
      )}
    </AdminShell>
  );
}

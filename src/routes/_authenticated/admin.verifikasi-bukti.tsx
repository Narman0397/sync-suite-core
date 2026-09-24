// Admin — Verifikasi Bukti Dokumen (permohonan / aset / izin_asn) via QR scan.
import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { ScanLine, CheckCircle2, XCircle, Loader2, ShieldAlert } from "lucide-react";
import { toast } from "sonner";
import { AdminShell } from "@/components/admin/AdminShell";
import { AdminGuard } from "@/components/admin/AdminGuard";
import { QrScanner } from "@/components/asn/QrScanner";
import { verifyBuktiDokumenByToken } from "@/features/bukti-dokumen/functions";

export const Route = createFileRoute("/_authenticated/admin/verifikasi-bukti")({
  head: () => ({
    meta: [
      { title: "Verifikasi Bukti Dokumen — Admin" },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: Page,
});

type Kind = "permohonan" | "aset" | "izin_asn";

type Bukti = {
  id: string;
  kind: Kind;
  nomor: string;
  status: "active" | "revoked";
  revoked_at: string | null;
  revoked_reason: string | null;
  signer_name: string | null;
  signer_position: string | null;
  signer_nip: string | null;
  created_at: string;
  opd: { nama: string; singkatan: string };
  snapshot_json: string | null;
  hash: string;
};

const KIND_LABEL: Record<Kind, string> = {
  permohonan: "Bukti Permohonan",
  aset: "Surat Aset (BMD)",
  izin_asn: "SK Izin/Cuti ASN",
};

function Page() {
  const verify = useServerFn(verifyBuktiDokumenByToken);
  const [scanning, setScanning] = useState(false);
  const [token, setToken] = useState("");
  const [manualToken, setManualToken] = useState("");
  const [bukti, setBukti] = useState<Bukti | null>(null);
  const [reason, setReason] = useState<"ok" | "revoked" | "not_found" | null>(null);
  const [notFound, setNotFound] = useState(false);
  const [busy, setBusy] = useState(false);

  function extractToken(raw: string): string {
    try {
      const u = new URL(raw);
      const m = u.pathname.match(/\/(?:v|verify)\/([^/?#]+)/);
      if (m) return decodeURIComponent(m[1]);
    } catch {
      /* not a URL */
    }
    return raw.trim();
  }

  async function checkToken(raw: string) {
    const t = extractToken(raw);
    if (!t) return;
    setToken(t);
    setBusy(true);
    setBukti(null);
    setNotFound(false);
    setReason(null);
    try {
      const r = await verify({ data: { token: t } });
      if (r.reason === "not_found" || !r.bukti) {
        setNotFound(true);
        setReason("not_found");
      } else {
        setBukti(r.bukti as Bukti);
        setReason(r.reason);
      }
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Gagal verifikasi");
    } finally {
      setBusy(false);
    }
  }

  function reset() {
    setToken("");
    setManualToken("");
    setBukti(null);
    setNotFound(false);
    setReason(null);
  }

  return (
    <AdminGuard>
      <AdminShell breadcrumb={[{ label: "Verifikasi Bukti Dokumen" }]}>
        <div className="mb-4 flex items-center justify-between">
          <div>
            <h2 className="font-display text-xl font-bold">Verifikasi Bukti Dokumen</h2>
            <p className="text-sm text-muted-foreground">
              Pindai QR pada bukti permohonan, surat aset, atau SK izin ASN untuk memverifikasi
              keaslian sebelum diproses lebih lanjut.
            </p>
          </div>
        </div>

        {!bukti && !notFound ? (
          <div className="grid gap-4 md:grid-cols-2">
            <div className="rounded-xl border border-border bg-card p-4">
              <div className="mb-2 flex items-center gap-2 font-medium">
                <ScanLine className="h-4 w-4" /> Scan QR
              </div>
              {scanning ? (
                <>
                  <QrScanner
                    onResult={(text) => {
                      setScanning(false);
                      checkToken(text);
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => setScanning(false)}
                    className="mt-3 inline-flex h-9 items-center rounded-md border border-border px-3 text-xs"
                  >
                    Batalkan
                  </button>
                </>
              ) : (
                <button
                  type="button"
                  onClick={() => setScanning(true)}
                  className="inline-flex h-10 items-center gap-2 rounded-md bg-gradient-primary px-4 text-sm font-semibold text-primary-foreground"
                >
                  <ScanLine className="h-4 w-4" /> Aktifkan Kamera
                </button>
              )}
            </div>

            <div className="rounded-xl border border-border bg-card p-4">
              <div className="mb-2 font-medium">Input Manual Token</div>
              <p className="mb-3 text-xs text-muted-foreground">
                Bila kamera tidak tersedia, salin token dari URL QR (`/v/&lt;token&gt;`) dan tempel
                di sini.
              </p>
              <div className="flex gap-2">
                <input
                  value={manualToken}
                  onChange={(e) => setManualToken(e.target.value)}
                  placeholder="Token atau URL bukti"
                  className="h-10 flex-1 rounded-md border border-border bg-background px-3 text-sm"
                />
                <button
                  type="button"
                  onClick={() => checkToken(manualToken)}
                  disabled={!manualToken || busy}
                  className="inline-flex h-10 items-center rounded-md bg-primary px-3 text-sm font-semibold text-primary-foreground disabled:opacity-50"
                >
                  {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : "Cek"}
                </button>
              </div>
            </div>
          </div>
        ) : notFound ? (
          <div className="rounded-xl border border-destructive/30 bg-destructive/5 p-6 text-center">
            <XCircle className="mx-auto h-10 w-10 text-destructive" />
            <h3 className="mt-3 font-display text-lg font-semibold text-destructive">
              Bukti tidak ditemukan
            </h3>
            <p className="mt-1 text-sm text-muted-foreground">
              Token tidak sesuai dengan dokumen mana pun di registri. Pastikan bukti yang ditunjukkan
              asli dan diterbitkan oleh sistem.
            </p>
            <button
              type="button"
              onClick={reset}
              className="mt-4 inline-flex h-9 items-center rounded-md bg-primary px-3 text-sm font-semibold text-primary-foreground"
            >
              Scan Ulang
            </button>
          </div>
        ) : bukti ? (
          <div className="rounded-xl border border-border bg-card p-6">
            <div className="mb-4 flex flex-wrap items-center gap-2">
              {reason === "revoked" ? (
                <ShieldAlert className="h-5 w-5 text-destructive" />
              ) : (
                <CheckCircle2 className="h-5 w-5 text-success" />
              )}
              <h3 className="font-display text-lg font-semibold">
                {reason === "revoked" ? "Bukti Sudah Dicabut" : "Bukti Sah"}
              </h3>
              <span className="rounded-full bg-primary/10 px-2 py-0.5 text-xs font-medium text-primary">
                {KIND_LABEL[bukti.kind]}
              </span>
              {reason === "revoked" && bukti.revoked_at && (
                <span className="rounded-full bg-destructive/10 px-2 py-0.5 text-xs font-medium text-destructive">
                  Dicabut {new Date(bukti.revoked_at).toLocaleString("id-ID")}
                </span>
              )}
            </div>

            <dl className="grid gap-3 text-sm sm:grid-cols-2">
              <div>
                <dt className="text-xs text-muted-foreground">Nomor</dt>
                <dd className="font-mono font-semibold">{bukti.nomor}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Status</dt>
                <dd className="font-medium capitalize">{bukti.status}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Diterbitkan</dt>
                <dd>{new Date(bukti.created_at).toLocaleString("id-ID")}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">OPD</dt>
                <dd>{bukti.opd.nama} ({bukti.opd.singkatan})</dd>
              </div>
              {bukti.signer_name && (
                <div className="sm:col-span-2 border-t border-border pt-3">
                  <dt className="text-xs text-muted-foreground">Ditandatangani oleh</dt>
                  <dd className="font-medium">
                    {bukti.signer_name}
                    {bukti.signer_position && (
                      <span className="ml-2 text-xs text-muted-foreground">
                        {bukti.signer_position}
                        {bukti.signer_nip ? ` · NIP ${bukti.signer_nip}` : ""}
                      </span>
                    )}
                  </dd>
                </div>
              )}
              {bukti.revoked_reason && (
                <div className="sm:col-span-2">
                  <dt className="text-xs text-muted-foreground">Alasan pencabutan</dt>
                  <dd className="text-destructive">{bukti.revoked_reason}</dd>
                </div>
              )}
              <div className="sm:col-span-2 border-t border-border pt-3">
                <dt className="text-xs text-muted-foreground">SHA-256</dt>
                <dd className="break-all font-mono text-[11px]">{bukti.hash}</dd>
              </div>
            </dl>

            <div className="mt-6 flex flex-wrap gap-2 border-t border-border pt-4">
              <button
                type="button"
                onClick={reset}
                className="inline-flex h-10 items-center rounded-md bg-primary px-4 text-sm font-semibold text-primary-foreground"
              >
                Scan Bukti Lain
              </button>
              <a
                href={`/verify/${token}`}
                target="_blank"
                rel="noreferrer"
                className="inline-flex h-10 items-center rounded-md border border-border px-4 text-sm font-medium"
              >
                Buka Halaman Verifikasi Publik
              </a>
            </div>
          </div>
        ) : null}
      </AdminShell>
    </AdminGuard>
  );
}
// Public verification portal: /verify/$token
// - Cek registri `bukti_dokumen` (Fase 2) — 3 jenis: permohonan/aset/izin_asn.
// - Verifikasi ulang via UPLOAD PDF: SERVER menghitung SHA-256 (tidak percaya client).
// - Fallback: token lama pada `permohonan.bukti_token` (kompatibilitas Fase 1).
import { createFileRoute } from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { useEffect, useState } from "react";
import {
  verifyBuktiDokumenByToken,
  verifyUploadedBukti,
} from "@/features/bukti-dokumen/functions";
import { Header } from "@/components/site/Header";
import { Footer } from "@/components/site/Footer";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { toast } from "sonner";
import { CheckCircle2, XCircle, FileText } from "lucide-react";

export const Route = createFileRoute("/verify/$token")({
  head: ({ params }) => ({
    meta: [
      { title: `Verifikasi Dokumen ${params.token.slice(0, 8)}` },
      { name: "description", content: "Halaman verifikasi keaslian dokumen resmi (server-side hash)." },
    ],
  }),
  component: Page,
});

type BuktiDokumen = {
  id: string;
  kind: "permohonan" | "aset" | "izin_asn";
  nomor: string;
  status: "active" | "revoked";
  revoked_at: string | null;
  revoked_reason: string | null;
  signer_name: string | null;
  signer_position: string | null;
  signer_nip: string | null;
  created_at: string;
  hash: string;
  opd: { nama: string; singkatan: string };
  snapshot_json: string | null;
};
type Loaded =
  | { state: "loading" }
  | { state: "invalid"; reason: string }
  | { state: "valid" | "revoked"; data: BuktiDokumen };

const MAX_UPLOAD_BYTES = 20 * 1024 * 1024;

const KIND_LABEL: Record<BuktiDokumen["kind"], string> = {
  permohonan: "Bukti Permohonan Layanan Publik",
  aset: "Surat Keterangan Aset / BMD",
  izin_asn: "Surat Keputusan Izin / Cuti ASN",
};

function Page() {
  const { token } = Route.useParams();
  const verifyNew = useServerFn(verifyBuktiDokumenByToken);
  const verifyUpload = useServerFn(verifyUploadedBukti);
  const [state, setState] = useState<Loaded>({ state: "loading" });
  const [reUpload, setReUpload] = useState<File | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const r = await verifyNew({ data: { token } });
        if (r.bukti) {
          setState({ state: r.valid ? "valid" : "revoked", data: r.bukti as BuktiDokumen });
          return;
        }
        setState({ state: "invalid", reason: r.reason ?? "not_found" });
      } catch (e) {
        setState({ state: "invalid", reason: e instanceof Error ? e.message : "Gagal verifikasi" });
      }
    })();
  }, [token, verifyNew]);

  async function reVerify() {
    if (!reUpload) return;
    if (reUpload.size === 0) { toast.error("File kosong"); return; }
    if (reUpload.size > MAX_UPLOAD_BYTES) { toast.error("PDF melebihi 20MB"); return; }
    if (reUpload.type && reUpload.type !== "application/pdf") { toast.error("File harus PDF"); return; }
    setBusy(true);
    try {
      const bytes = new Uint8Array(await reUpload.arrayBuffer());
      let bin = "";
      for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
      const r = await verifyUpload({ data: { pdfBase64: btoa(bin), token } });
      if (r.match) {
        if (r.reason === "revoked") {
          toast.error("Dokumen cocok tetapi telah DICABUT.");
        } else {
          toast.success(`Dokumen COCOK. Diterbitkan ${new Date(r.signed_at).toLocaleString("id-ID")}`);
        }
      } else {
        toast.error("Dokumen telah dimodifikasi atau tidak sesuai dengan dokumen asli yang diterbitkan.");
      }
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Gagal verifikasi unggahan");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex min-h-screen flex-col">
      <Header />
      <main className="container mx-auto flex-1 space-y-6 py-8">
        <BuktiVerifyCard state={state} />
        <Card className="mx-auto max-w-2xl">
          <CardHeader>
            <CardTitle>Verifikasi Ulang dengan Upload PDF</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Input type="file" accept="application/pdf" onChange={(e) => setReUpload(e.target.files?.[0] ?? null)} />
            <Button onClick={reVerify} disabled={!reUpload || busy}>
              {busy ? "Memverifikasi…" : "Verifikasi Server-Side"}
            </Button>
            <p className="text-xs text-muted-foreground">
              PDF diunggah ke server. Server menghitung SHA-256 dan membandingkan dengan registri resmi (client hash tidak dipercaya).
            </p>
          </CardContent>
        </Card>
      </main>
      <Footer />
    </div>
  );
}

function BuktiVerifyCard({ state }: { state: Loaded }) {
  if (state.state === "loading") {
    return <Card className="mx-auto max-w-2xl"><CardContent className="py-8 text-center text-muted-foreground">Memuat verifikasi…</CardContent></Card>;
  }
  if (state.state === "invalid") {
    return (
      <Card className="mx-auto max-w-2xl border-destructive/40">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-destructive"><XCircle className="h-5 w-5" /> Bukti Tidak Valid</CardTitle>
        </CardHeader>
        <CardContent className="text-sm text-muted-foreground">
          Token tidak ditemukan atau tidak dikenali sistem. ({state.reason})
        </CardContent>
      </Card>
    );
  }
  const d = state.data;
  const isValid = state.state === "valid";
  return (
    <Card className={`mx-auto max-w-2xl ${isValid ? "border-success/40" : "border-destructive/40"}`}>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          {isValid ? <CheckCircle2 className="h-5 w-5 text-success" /> : <XCircle className="h-5 w-5 text-destructive" />}
          {isValid ? "Dokumen Sah" : "Dokumen Dicabut"}
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-2 text-sm">
        <dl className="grid gap-2 sm:grid-cols-2">
          <div><dt className="text-xs text-muted-foreground">Jenis</dt><dd>{KIND_LABEL[d.kind]}</dd></div>
          <div><dt className="text-xs text-muted-foreground">Nomor</dt><dd className="font-mono">{d.nomor}</dd></div>
          <div className="sm:col-span-2"><dt className="text-xs text-muted-foreground">OPD Penerbit</dt><dd>{d.opd.nama} ({d.opd.singkatan})</dd></div>
          <div><dt className="text-xs text-muted-foreground">Diterbitkan</dt><dd>{new Date(d.created_at).toLocaleString("id-ID")}</dd></div>
          <div><dt className="text-xs text-muted-foreground">Penandatangan</dt><dd>{d.signer_name ?? "-"}<br /><span className="text-xs text-muted-foreground">{d.signer_position ?? ""}{d.signer_nip ? ` · NIP ${d.signer_nip}` : ""}</span></dd></div>
          <div className="sm:col-span-2"><dt className="text-xs text-muted-foreground">Hash SHA-256</dt><dd className="break-all font-mono text-xs">{d.hash}</dd></div>
          {!isValid && (
            <div className="sm:col-span-2 rounded border border-destructive/30 bg-destructive/5 p-2 text-destructive">
              <strong>Dicabut</strong> {d.revoked_at ? `pada ${new Date(d.revoked_at).toLocaleString("id-ID")}` : ""}
              {d.revoked_reason ? ` — ${d.revoked_reason}` : ""}
            </div>
          )}
        </dl>
      </CardContent>
    </Card>
  );
}
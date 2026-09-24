// Editor Template Bukti Dokumen — 3 jenis (permohonan, aset, izin_asn)
// × cakupan Global atau per-OPD. Super/pemda admin dapat mengelola semua;
// admin OPD hanya bisa mengelola template OPD-nya.
import { lazy, Suspense, useEffect, useMemo, useRef, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { Save, Loader2, FileText, Eye, RotateCcw } from "lucide-react";
import { toast } from "sonner";
import { AdminShell } from "@/components/admin/AdminShell";
import { AdminGuard } from "@/components/admin/AdminGuard";
import type { WordLikeEditorHandle } from "@/features/documents/editor/WordLikeEditor";
const WordLikeEditor = lazy(() =>
  import("@/features/documents/editor/WordLikeEditor").then((m) => ({ default: m.WordLikeEditor })),
);
import {
  getBuktiDokumenTemplate,
  saveBuktiDokumenTemplate,
  resetBuktiDokumenTemplate,
  listBuktiTemplateScope,
} from "@/features/bukti-dokumen/functions";

export const Route = createFileRoute("/_authenticated/admin/template-dokumen")({
  head: () => ({
    meta: [
      { title: "Template Bukti Dokumen — Admin" },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: Page,
});

type Kind = "permohonan" | "aset" | "izin_asn";

const KIND_LABEL: Record<Kind, string> = {
  permohonan: "Bukti Permohonan Layanan",
  aset: "Surat Keterangan Aset (BMD)",
  izin_asn: "SK Izin / Cuti ASN",
};

const PLACEHOLDERS_BY_KIND: Record<Kind, Array<{ key: string; desc: string }>> = {
  permohonan: [
    { key: "{{bukti.nomor}}", desc: "Nomor bukti" },
    { key: "{{permohonan.kode}}", desc: "Kode permohonan" },
    { key: "{{permohonan.judul}}", desc: "Judul permohonan" },
    { key: "{{permohonan.kategori}}", desc: "Kategori layanan" },
    { key: "{{permohonan.tanggal_masuk}}", desc: "Tanggal pengajuan" },
    { key: "{{pemohon.nama}}", desc: "Nama pemohon" },
    { key: "{{pemohon.nik}}", desc: "NIK pemohon" },
    { key: "{{pemohon.no_hp}}", desc: "No HP pemohon" },
    { key: "{{pemohon.alamat}}", desc: "Alamat pemohon" },
    { key: "{{pemohon.desa}}", desc: "Desa pemohon" },
    { key: "{{opd.nama}}", desc: "Nama OPD" },
    { key: "{{opd.singkatan}}", desc: "Singkatan OPD" },
    { key: "{{sistem.qr_code}}", desc: "Gambar QR verifikasi" },
  ],
  aset: [
    { key: "{{bukti.nomor}}", desc: "Nomor surat" },
    { key: "{{aset.kode}}", desc: "Kode aset" },
    { key: "{{aset.nama}}", desc: "Nama barang" },
    { key: "{{aset.kategori}}", desc: "Kategori aset" },
    { key: "{{aset.kondisi}}", desc: "Kondisi" },
    { key: "{{aset.merk}}", desc: "Merk" },
    { key: "{{aset.nomor_seri}}", desc: "Nomor seri" },
    { key: "{{aset.lokasi}}", desc: "Lokasi" },
    { key: "{{aset.nilai_perolehan}}", desc: "Nilai perolehan" },
    { key: "{{aset.tanggal_perolehan}}", desc: "Tanggal perolehan" },
    { key: "{{pemegang.nama}}", desc: "Pemegang aset" },
    { key: "{{pemegang.nip}}", desc: "NIP pemegang" },
    { key: "{{opd.nama}}", desc: "OPD" },
    { key: "{{opd.singkatan}}", desc: "Singkatan OPD" },
    { key: "{{signer.nama}}", desc: "Nama penandatangan" },
    { key: "{{signer.jabatan}}", desc: "Jabatan penandatangan" },
    { key: "{{signer.nip}}", desc: "NIP penandatangan" },
    { key: "{{sistem.qr_code}}", desc: "QR verifikasi" },
  ],
  izin_asn: [
    { key: "{{bukti.nomor}}", desc: "Nomor SK" },
    { key: "{{asn.nama}}", desc: "Nama ASN" },
    { key: "{{asn.nip}}", desc: "NIP" },
    { key: "{{asn.jabatan}}", desc: "Jabatan" },
    { key: "{{opd.nama}}", desc: "OPD" },
    { key: "{{opd.singkatan}}", desc: "Singkatan OPD" },
    { key: "{{izin.jenis}}", desc: "Jenis izin/cuti" },
    { key: "{{izin.dari}}", desc: "Tanggal mulai" },
    { key: "{{izin.sampai}}", desc: "Tanggal selesai" },
    { key: "{{izin.alasan}}", desc: "Alasan" },
    { key: "{{izin.catatan_approval}}", desc: "Catatan persetujuan" },
    { key: "{{signer.nama}}", desc: "Nama penandatangan" },
    { key: "{{signer.jabatan}}", desc: "Jabatan penandatangan" },
    { key: "{{signer.nip}}", desc: "NIP penandatangan" },
    { key: "{{sistem.qr_code}}", desc: "QR verifikasi" },
  ],
};

function Page() {
  const listScope = useServerFn(listBuktiTemplateScope);
  const getTpl = useServerFn(getBuktiDokumenTemplate);
  const saveTpl = useServerFn(saveBuktiDokumenTemplate);
  const resetTpl = useServerFn(resetBuktiDokumenTemplate);

  const [kind, setKind] = useState<Kind>("permohonan");
  const [opdId, setOpdId] = useState<string | null>(null);
  const [scope, setScope] = useState<"global" | "opd">("global");
  const [opds, setOpds] = useState<Array<{ id: string; nama: string; singkatan: string }>>([]);
  const [html, setHtml] = useState("");
  const [initial, setInitial] = useState("");
  const [isOverride, setIsOverride] = useState(false);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const editorRef = useRef<WordLikeEditorHandle | null>(null);

  const placeholders = useMemo(() => PLACEHOLDERS_BY_KIND[kind], [kind]);

  // Load scope once.
  useEffect(() => {
    (async () => {
      try {
        const r = await listScope();
        setScope(r.scope);
        setOpds(r.opds);
        if (r.scope === "opd" && r.opds[0]) setOpdId(r.opds[0].id);
      } catch (e) {
        toast.error(e instanceof Error ? e.message : "Gagal memuat cakupan");
      }
    })();
  }, [listScope]);

  // Reload template on kind/opd change.
  useEffect(() => {
    let cancel = false;
    (async () => {
      setLoading(true);
      try {
        const r = await getTpl({ data: { kind, opd_id: opdId } });
        if (cancel) return;
        setHtml(r.html);
        setInitial(r.html);
        setIsOverride(r.isOverride);
        editorRef.current?.setHTML(r.html);
      } catch (e) {
        if (!cancel) toast.error(e instanceof Error ? e.message : "Gagal memuat template");
      } finally {
        if (!cancel) setLoading(false);
      }
    })();
    return () => { cancel = true; };
  }, [kind, opdId, getTpl]);

  async function onSave() {
    setBusy(true);
    try {
      await saveTpl({ data: { kind, opd_id: opdId, html } });
      setInitial(html);
      setIsOverride(true);
      toast.success("Template disimpan");
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Gagal menyimpan");
    } finally {
      setBusy(false);
    }
  }

  async function onReset() {
    if (!confirm("Kembalikan ke template default sistem? Perubahan akan dihapus.")) return;
    setBusy(true);
    try {
      await resetTpl({ data: { kind, opd_id: opdId } });
      const r = await getTpl({ data: { kind, opd_id: opdId } });
      setHtml(r.html);
      setInitial(r.html);
      setIsOverride(false);
      editorRef.current?.setHTML(r.html);
      toast.success("Template dikembalikan ke default");
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Gagal reset");
    } finally {
      setBusy(false);
    }
  }

  return (
    <AdminGuard>
      <AdminShell breadcrumb={[{ label: "Template Bukti Dokumen" }]}>
        <div className="mb-4 flex flex-wrap items-start justify-between gap-3">
          <div>
            <h2 className="font-display text-xl font-bold flex items-center gap-2">
              <FileText className="h-5 w-5" /> Template Bukti Dokumen
            </h2>
            <p className="mt-1 max-w-2xl text-sm text-muted-foreground">
              Kelola template 3 jenis bukti: permohonan layanan, aset (BMD), dan SK izin/cuti ASN.
              Template per-OPD akan menimpa template global untuk OPD tersebut.
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            {isOverride && (
              <button
                type="button"
                onClick={onReset}
                disabled={busy || loading}
                className="inline-flex h-9 items-center gap-1 rounded-md border border-border px-3 text-xs disabled:opacity-50"
              >
                <RotateCcw className="h-3.5 w-3.5" /> Kembalikan ke Default
              </button>
            )}
            <button
              type="button"
              onClick={() => setShowPreview((v) => !v)}
              className="inline-flex h-9 items-center gap-1 rounded-md border border-border px-3 text-xs"
            >
              <Eye className="h-3.5 w-3.5" /> {showPreview ? "Sembunyikan" : "Preview"}
            </button>
            <button
              type="button"
              onClick={onSave}
              disabled={busy || loading || html === initial}
              className="inline-flex h-9 items-center gap-1 rounded-md bg-gradient-primary px-3 text-xs font-semibold text-primary-foreground disabled:opacity-50"
            >
              {busy ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Save className="h-3.5 w-3.5" />}
              Simpan
            </button>
          </div>
        </div>

        <div className="mb-4 flex flex-wrap items-center gap-3 rounded-xl border border-border bg-card p-3">
          <label className="text-xs font-medium text-muted-foreground">Jenis:</label>
          <select
            value={kind}
            onChange={(e) => setKind(e.target.value as Kind)}
            className="h-9 rounded-md border border-border bg-background px-2 text-sm"
          >
            {(Object.keys(KIND_LABEL) as Kind[]).map((k) => (
              <option key={k} value={k}>{KIND_LABEL[k]}</option>
            ))}
          </select>
          <label className="ml-3 text-xs font-medium text-muted-foreground">Cakupan:</label>
          <select
            value={opdId ?? ""}
            onChange={(e) => setOpdId(e.target.value || null)}
            disabled={scope === "opd"}
            className="h-9 rounded-md border border-border bg-background px-2 text-sm disabled:opacity-60"
          >
            {scope === "global" && <option value="">Global (semua OPD)</option>}
            {opds.map((o) => (
              <option key={o.id} value={o.id}>{o.singkatan} — {o.nama}</option>
            ))}
          </select>
          {isOverride ? (
            <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[11px] font-medium text-primary">
              Override aktif
            </span>
          ) : (
            <span className="rounded-full bg-muted px-2 py-0.5 text-[11px] text-muted-foreground">
              Memakai default sistem
            </span>
          )}
        </div>

        <div className="grid gap-4 lg:grid-cols-[2fr_1fr]">
          <div className="rounded-xl border border-border bg-card p-4">
            <label className="mb-2 block text-sm font-medium">Editor Dokumen</label>
            {loading ? (
              <div className="grid h-96 place-items-center text-sm text-muted-foreground">Memuat…</div>
            ) : (
              <Suspense fallback={<div className="grid h-96 place-items-center text-sm text-muted-foreground">Memuat editor…</div>}>
                <WordLikeEditor
                  key={`${kind}-${opdId ?? "global"}`}
                  ref={editorRef}
                  initialHTML={html}
                  onChange={setHtml}
                  placeholders={placeholders}
                />
              </Suspense>
            )}
            <p className="mt-2 text-[11px] text-muted-foreground">
              Tip: ketik <kbd className="rounded border border-border bg-muted px-1">/</kbd> untuk sisipkan placeholder.
            </p>
            {showPreview && (
              <div className="mt-4">
                <div className="mb-2 text-xs font-medium text-muted-foreground">
                  Preview HTML (placeholder belum di-render)
                </div>
                <div
                  className="prose prose-sm max-w-none rounded-md border border-border bg-surface p-4"
                  dangerouslySetInnerHTML={{ __html: html }}
                />
              </div>
            )}
          </div>

          <div className="rounded-xl border border-border bg-card p-4">
            <div className="mb-2 text-sm font-medium">Placeholder — {KIND_LABEL[kind]}</div>
            <p className="mb-3 text-xs text-muted-foreground">Klik untuk menyisipkan di kursor.</p>
            <ul className="space-y-1.5 text-xs">
              {placeholders.map((p) => (
                <li key={p.key}>
                  <button
                    type="button"
                    onClick={() => {
                      editorRef.current?.insertPlaceholder(p.key);
                      toast.success(`Disisipkan: ${p.key}`);
                    }}
                    className="w-full rounded border border-border bg-background px-2 py-1.5 text-left hover:bg-muted"
                  >
                    <code className="font-mono text-primary">{p.key}</code>
                    <div className="text-[10px] text-muted-foreground">{p.desc}</div>
                  </button>
                </li>
              ))}
            </ul>
            <div className="mt-4 rounded-md bg-primary-soft p-3 text-xs">
              <strong>Prioritas template:</strong>
              <ol className="ml-4 mt-1 list-decimal space-y-0.5">
                <li>Override per-OPD (bila diset)</li>
                <li>Override Global</li>
                <li>Default sistem</li>
              </ol>
            </div>
          </div>
        </div>
      </AdminShell>
    </AdminGuard>
  );
}
// Context builder untuk 3 jenis bukti. Menghasilkan MergeContext yang dapat
// dikonsumsi oleh `mergeTemplate` dari features/documents/placeholder/engine.
import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/integrations/supabase/types";
import type { MergeContext } from "@/features/documents/placeholder/engine";
import { buildPermohonanContext } from "@/features/documents/services/permohonan-context.service";
import { QR_MARKER } from "./pdf-builder";
import type { BuktiKind } from "./templates";

type SB = SupabaseClient<Database>;

export interface BuildCtxInput {
  kind: BuktiKind;
  entity_id: string;
  nomor: string;
  verify_url: string;
  signer?: { user_id?: string | null; nama?: string | null; jabatan?: string | null; nip?: string | null };
}

function fmtDate(v: string | null | undefined): string {
  if (!v) return "-";
  try { return new Date(v).toLocaleDateString("id-ID"); } catch { return String(v); }
}
function num(n: unknown): string {
  const x = typeof n === "number" ? n : n ? Number(n) : 0;
  if (!isFinite(x)) return "0";
  return x.toLocaleString("id-ID");
}

async function opdInfo(sb: SB, opd_id: string | null | undefined) {
  if (!opd_id) return { nama: "-", singkatan: "-", id: null as string | null };
  const { data } = await sb.from("opd").select("id,nama,singkatan").eq("id", opd_id).maybeSingle();
  return { nama: data?.nama ?? "-", singkatan: data?.singkatan ?? "-", id: data?.id ?? opd_id };
}
async function profileInfo(sb: SB, uid: string | null | undefined) {
  if (!uid) return { nama: "-", nip: "-", jabatan: "-", no_hp: "-", email: "-" };
  const { data } = await sb.from("profiles").select("nama_lengkap,nip,jabatan,no_hp").eq("id", uid).maybeSingle();
  return {
    nama: data?.nama_lengkap ?? "-",
    nip: data?.nip ?? "-",
    jabatan: data?.jabatan ?? "-",
    no_hp: data?.no_hp ?? "-",
    email: "-",
  };
}

function baseCtx(nomor: string, signer: BuildCtxInput["signer"]): MergeContext {
  return {
    submission: {},
    profile: {},
    workflow: {},
    document: {},
    system: { qr_code: QR_MARKER, tanggal_terbit: new Date().toLocaleDateString("id-ID") },
    // extras added by kind-specific builder
    bukti: { nomor },
    signer: {
      nama: signer?.nama ?? "-",
      jabatan: signer?.jabatan ?? "-",
      nip: signer?.nip ?? "-",
    },
    sistem: { qr_code: QR_MARKER },
  } as unknown as MergeContext;
}

export async function buildBuktiContext(
  sb: SB,
  input: BuildCtxInput,
): Promise<{ context: MergeContext; opd_id: string | null; snapshot: Record<string, unknown> }> {
  const ctx = baseCtx(input.nomor, input.signer) as unknown as Record<string, unknown>;

  if (input.kind === "permohonan") {
    const base = await buildPermohonanContext(sb, input.entity_id, { verify_url: input.verify_url });
    // Merge base into ctx (buildPermohonanContext already returns fully-populated).
    const merged: MergeContext = {
      ...base,
      system: { ...(base.system as Record<string, unknown>), qr_code: QR_MARKER, verify_url: input.verify_url },
    };
    (merged as unknown as Record<string, unknown>).bukti = { nomor: input.nomor };
    (merged as unknown as Record<string, unknown>).sistem = { ...((merged as unknown as { sistem?: Record<string, unknown> }).sistem ?? {}), qr_code: QR_MARKER, verify_url: input.verify_url };
    (merged as unknown as Record<string, unknown>).signer = {
      nama: input.signer?.nama ?? "-",
      jabatan: input.signer?.jabatan ?? "-",
      nip: input.signer?.nip ?? "-",
    };
    const { data: p } = await sb.from("permohonan").select("opd_id").eq("id", input.entity_id).maybeSingle();
    return { context: merged, opd_id: p?.opd_id ?? null, snapshot: { kind: "permohonan", permohonan_id: input.entity_id } };
  }

  if (input.kind === "aset") {
    const { data: a } = await sb.from("aset")
      .select("id,kode,nama,kategori,kondisi,merk,nomor_seri,lokasi,nilai_perolehan,tanggal_perolehan,opd_id,pemegang_user_id")
      .eq("id", input.entity_id)
      .maybeSingle();
    if (!a) throw new Error("Aset tidak ditemukan");
    const [opd, pem] = await Promise.all([opdInfo(sb, a.opd_id), profileInfo(sb, a.pemegang_user_id)]);
    ctx.aset = {
      kode: a.kode, nama: a.nama, kategori: a.kategori ?? "-",
      kondisi: a.kondisi, merk: a.merk ?? "-", nomor_seri: a.nomor_seri ?? "-",
      lokasi: a.lokasi ?? "-",
      nilai_perolehan: num(a.nilai_perolehan),
      tanggal_perolehan: fmtDate(a.tanggal_perolehan),
    };
    ctx.pemegang = pem;
    ctx.opd = { nama: opd.nama, singkatan: opd.singkatan };
    (ctx.system as Record<string, unknown>).verify_url = input.verify_url;
    (ctx.sistem as Record<string, unknown>).verify_url = input.verify_url;
    return {
      context: ctx as unknown as MergeContext,
      opd_id: a.opd_id ?? null,
      snapshot: { kind: "aset", aset_id: a.id, kode: a.kode, nama: a.nama },
    };
  }

  // izin_asn
  const { data: iz } = await sb.from("pengajuan_izin")
    .select("id,user_id,opd_id,jenis,dari,sampai,alasan,catatan_approval,approved_by,approved_at,status")
    .eq("id", input.entity_id)
    .maybeSingle();
  if (!iz) throw new Error("Pengajuan izin tidak ditemukan");
  if (iz.status !== "approved") throw new Error("Izin belum disetujui");
  const [opd, asn, approver] = await Promise.all([
    opdInfo(sb, iz.opd_id),
    profileInfo(sb, iz.user_id),
    profileInfo(sb, iz.approved_by),
  ]);
  ctx.asn = { nama: asn.nama, nip: asn.nip, jabatan: asn.jabatan };
  ctx.izin = {
    jenis: iz.jenis,
    dari: fmtDate(iz.dari),
    sampai: fmtDate(iz.sampai),
    alasan: iz.alasan ?? "-",
    catatan_approval: iz.catatan_approval ?? "",
  };
  ctx.opd = { nama: opd.nama, singkatan: opd.singkatan };
  if (!input.signer?.nama) {
    ctx.signer = { nama: approver.nama, jabatan: approver.jabatan, nip: approver.nip };
  }
  (ctx.system as Record<string, unknown>).verify_url = input.verify_url;
  (ctx.sistem as Record<string, unknown>).verify_url = input.verify_url;
  return {
    context: ctx as unknown as MergeContext,
    opd_id: iz.opd_id ?? null,
    snapshot: { kind: "izin_asn", izin_id: iz.id, jenis: iz.jenis },
  };
}
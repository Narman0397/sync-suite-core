// Server functions bukti-dokumen (Phase 2A).
// - generateBukti: menerbitkan bukti (PDF + row registri + upload ke bucket privat).
// - getBuktiSignedUrl: URL unduh singkat (10 menit).
// - listBuktiForEntity: histori bukti per entitas.
// - verifyBuktiByToken: PUBLIC — dipakai halaman /verify/$token.
// - verifyUploadedBukti: PUBLIC — server menghitung SHA-256 dari PDF upload dan
//   membandingkan dengan registri (hash client tidak dipercaya).
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";
import { mergeTemplate } from "@/features/documents/placeholder/engine";
import { renderBuktiPdf, sha256Hex, makeToken, QR_MARKER } from "./core/pdf-builder";
import { defaultTemplateHtml, type BuktiKind } from "./core/templates";
import { buildBuktiContext } from "./core/context";

const BUCKET = "bukti-dokumen";
const KIND = z.enum(["permohonan", "aset", "izin_asn"]);

async function assertTemplateManager(sb: Awaited<ReturnType<typeof getAdmin>>, userId: string) {
  const { data: isSuper } = await sb.rpc("has_role", { _user_id: userId, _role: "super_admin" });
  if (isSuper) return { scope: "global" as const, opd_id: null as string | null };
  const { data: isPemda } = await sb.rpc("has_role", { _user_id: userId, _role: "admin_pemda" });
  if (isPemda) return { scope: "global" as const, opd_id: null as string | null };
  const { data: isOpd } = await sb.rpc("has_role", { _user_id: userId, _role: "admin_opd" });
  if (isOpd) {
    const { data: myOpd } = await sb.rpc("get_user_opd", { _user_id: userId });
    if (myOpd) return { scope: "opd" as const, opd_id: myOpd as string };
  }
  throw new Error("Forbidden");
}

export const getBuktiDokumenTemplate = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) =>
    z.object({ kind: KIND, opd_id: z.string().uuid().nullable() }).parse(i),
  )
  .handler(async ({ data, context }) => {
    const sb = await getAdmin();
    const mgr = await assertTemplateManager(sb, context.userId);
    if (mgr.scope === "opd" && data.opd_id !== mgr.opd_id) throw new Error("Forbidden");
    const q = sb.from("bukti_template_override").select("html,updated_at").eq("kind", data.kind);
    const { data: row } = data.opd_id
      ? await q.eq("opd_id", data.opd_id).maybeSingle()
      : await q.is("opd_id", null).maybeSingle();
    return {
      html: row?.html ?? defaultTemplateHtml(data.kind),
      isOverride: !!row,
      updated_at: row?.updated_at ?? null,
      default_html: defaultTemplateHtml(data.kind),
    };
  });

export const saveBuktiDokumenTemplate = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) =>
    z.object({
      kind: KIND,
      opd_id: z.string().uuid().nullable(),
      html: z.string().max(100000),
    }).parse(i),
  )
  .handler(async ({ data, context }) => {
    const sb = await getAdmin();
    const mgr = await assertTemplateManager(sb, context.userId);
    if (mgr.scope === "opd" && data.opd_id !== mgr.opd_id) throw new Error("Forbidden");
    const q = sb.from("bukti_template_override").select("id").eq("kind", data.kind);
    const { data: existing } = data.opd_id
      ? await q.eq("opd_id", data.opd_id).maybeSingle()
      : await q.is("opd_id", null).maybeSingle();
    if (existing) {
      const { error } = await sb.from("bukti_template_override")
        .update({ html: data.html, updated_by: context.userId })
        .eq("id", existing.id);
      if (error) throw new Error(error.message);
    } else {
      const { error } = await sb.from("bukti_template_override")
        .insert({ kind: data.kind, opd_id: data.opd_id, html: data.html, updated_by: context.userId });
      if (error) throw new Error(error.message);
    }
    return { ok: true as const };
  });

export const resetBuktiDokumenTemplate = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) =>
    z.object({ kind: KIND, opd_id: z.string().uuid().nullable() }).parse(i),
  )
  .handler(async ({ data, context }) => {
    const sb = await getAdmin();
    const mgr = await assertTemplateManager(sb, context.userId);
    if (mgr.scope === "opd" && data.opd_id !== mgr.opd_id) throw new Error("Forbidden");
    const q = sb.from("bukti_template_override").delete().eq("kind", data.kind);
    const { error } = data.opd_id ? await q.eq("opd_id", data.opd_id) : await q.is("opd_id", null);
    if (error) throw new Error(error.message);
    return { ok: true as const };
  });

export const listBuktiTemplateScope = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const sb = await getAdmin();
    const mgr = await assertTemplateManager(sb, context.userId);
    if (mgr.scope === "opd") {
      const { data: opd } = await sb.from("opd").select("id,nama,singkatan").eq("id", mgr.opd_id!).maybeSingle();
      return { scope: "opd" as const, opds: opd ? [opd] : [] };
    }
    const { data: opds } = await sb.from("opd").select("id,nama,singkatan").order("nama");
    return { scope: "global" as const, opds: opds ?? [] };
  });

async function getTemplateHtml(
  sb: Awaited<ReturnType<typeof getAdmin>>,
  kind: BuktiKind,
  opd_id: string | null,
): Promise<string> {
  if (opd_id) {
    const { data } = await sb.from("bukti_template_override")
      .select("html")
      .eq("kind", kind)
      .eq("opd_id", opd_id)
      .maybeSingle();
    if (data?.html && data.html.trim()) return data.html;
  }
  const { data: g } = await sb.from("bukti_template_override")
    .select("html")
    .eq("kind", kind)
    .is("opd_id", null)
    .maybeSingle();
  if (g?.html && g.html.trim()) return g.html;
  return defaultTemplateHtml(kind);
}

async function getAdmin() {
  const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
  return supabaseAdmin;
}

async function assertAccess(
  sb: Awaited<ReturnType<typeof getAdmin>>,
  kind: BuktiKind,
  entity_id: string,
  userId: string,
): Promise<{ ok: boolean; opd_id: string | null }> {
  const { data: isSuper } = await sb.rpc("has_role", { _user_id: userId, _role: "super_admin" });
  const isSuperOk = !!isSuper;
  if (kind === "permohonan") {
    const { data: p } = await sb.from("permohonan").select("opd_id,pemohon_id").eq("id", entity_id).maybeSingle();
    if (!p) return { ok: false, opd_id: null };
    if (isSuperOk || p.pemohon_id === userId) return { ok: true, opd_id: p.opd_id };
    const { data: isOpd } = await sb.rpc("has_role", { _user_id: userId, _role: "admin_opd" });
    if (isOpd) {
      const { data: myOpd } = await sb.rpc("get_user_opd", { _user_id: userId });
      return { ok: myOpd === p.opd_id, opd_id: p.opd_id };
    }
    return { ok: false, opd_id: p.opd_id };
  }
  if (kind === "aset") {
    const { data: a } = await sb.from("aset").select("opd_id").eq("id", entity_id).maybeSingle();
    if (!a) return { ok: false, opd_id: null };
    if (isSuperOk) return { ok: true, opd_id: a.opd_id };
    const { data: isOpd } = await sb.rpc("has_role", { _user_id: userId, _role: "admin_opd" });
    if (isOpd) {
      const { data: myOpd } = await sb.rpc("get_user_opd", { _user_id: userId });
      return { ok: myOpd === a.opd_id, opd_id: a.opd_id };
    }
    return { ok: false, opd_id: a.opd_id };
  }
  // izin_asn
  const { data: iz } = await sb.from("pengajuan_izin").select("opd_id,user_id,approved_by").eq("id", entity_id).maybeSingle();
  if (!iz) return { ok: false, opd_id: null };
  if (isSuperOk || iz.approved_by === userId) return { ok: true, opd_id: iz.opd_id };
  const { data: isOpd } = await sb.rpc("has_role", { _user_id: userId, _role: "admin_opd" });
  if (isOpd) {
    const { data: myOpd } = await sb.rpc("get_user_opd", { _user_id: userId });
    return { ok: myOpd === iz.opd_id, opd_id: iz.opd_id };
  }
  return { ok: false, opd_id: iz.opd_id };
}

export const generateBukti = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) =>
    z.object({
      kind: KIND,
      entity_id: z.string().uuid(),
      site_origin: z.string().url().optional(),
    }).parse(i),
  )
  .handler(async ({ data, context }) => {
    const { userId } = context;
    const sb = await getAdmin();
    const acc = await assertAccess(sb, data.kind, data.entity_id, userId);
    if (!acc.ok) throw new Error("Forbidden");

    // Nomor bukti (per OPD × jenis × bulan).
    const { data: nomorRow, error: nomorErr } = await sb.rpc("next_bukti_nomor", {
      _kind: data.kind,
      _opd_id: (acc.opd_id ?? null) as unknown as string,
    });
    if (nomorErr) throw new Error(`Gagal mengambil nomor: ${nomorErr.message}`);
    const nomor = String(nomorRow ?? "");
    if (!nomor) throw new Error("Gagal mengambil nomor bukti");

    // Signer info dari profil user pembuat.
    const { data: prof } = await sb.from("profiles").select("nama_lengkap,jabatan,nip").eq("id", userId).maybeSingle();
    const signer = {
      user_id: userId,
      nama: prof?.nama_lengkap ?? null,
      jabatan: prof?.jabatan ?? null,
      nip: prof?.nip ?? null,
    };

    const token = makeToken();
    const origin = data.site_origin ?? "";
    const verify_url = `${origin}/verify/${token}`;

    const { context: ctx, opd_id, snapshot } = await buildBuktiContext(sb, {
      kind: data.kind,
      entity_id: data.entity_id,
      nomor,
      verify_url,
      signer,
    });
    const templateHtml = await getTemplateHtml(sb, data.kind, opd_id);
    // Lindungi marker QR sebelum merge (agar mergeTemplate tidak menghilangkan).
    const pre = templateHtml.replace(/\{\{\s*sistem\.qr_code\s*\}\}/gi, QR_MARKER)
      .replace(/\{\{\s*system\.qr_code\s*\}\}/gi, QR_MARKER);
    const merged = mergeTemplate(pre, ctx);
    const bytes = await renderBuktiPdf(merged, verify_url);
    const hash = await sha256Hex(bytes);
    const path = `${data.kind}/${data.entity_id}/${token}.pdf`;

    const { error: upErr } = await sb.storage.from(BUCKET).upload(path, bytes, {
      contentType: "application/pdf",
      upsert: true,
    });
    if (upErr) throw new Error(`Gagal upload PDF: ${upErr.message}`);

    const { data: inserted, error: insErr } = await sb.from("bukti_dokumen").insert({
      kind: data.kind,
      entity_id: data.entity_id,
      opd_id,
      nomor,
      token,
      path,
      hash,
      signer_user_id: signer.user_id,
      signer_name: signer.nama,
      signer_position: signer.jabatan,
      signer_nip: signer.nip,
      snapshot: snapshot as unknown as never,
      created_by: userId,
    }).select("id").single();
    if (insErr) throw new Error(`Gagal simpan registri: ${insErr.message}`);

    const { data: signed } = await sb.storage.from(BUCKET).createSignedUrl(path, 600);
    return {
      id: inserted.id,
      token,
      nomor,
      path,
      hash,
      url: signed?.signedUrl ?? null,
      verify_url,
    };
  });

export const getBuktiSignedUrl = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => z.object({ id: z.string().uuid() }).parse(i))
  .handler(async ({ data }) => {
    const sb = await getAdmin();
    const { data: row } = await sb.from("bukti_dokumen").select("path,status").eq("id", data.id).maybeSingle();
    if (!row) throw new Error("Bukti tidak ditemukan");
    const { data: signed } = await sb.storage.from(BUCKET).createSignedUrl(row.path, 600);
    return { url: signed?.signedUrl ?? null, status: row.status as "active" | "revoked" };
  });

export const listBuktiForEntity = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) =>
    z.object({ kind: KIND, entity_id: z.string().uuid() }).parse(i),
  )
  .handler(async ({ data }) => {
    const sb = await getAdmin();
    const { data: rows } = await sb.from("bukti_dokumen")
      .select("id,nomor,token,path,hash,status,signer_name,signer_position,signer_nip,created_at,revoked_at,revoked_reason")
      .eq("kind", data.kind)
      .eq("entity_id", data.entity_id)
      .order("created_at", { ascending: false });
    return { rows: rows ?? [] };
  });

// PUBLIC — dipakai halaman /verify/$token.
export const verifyBuktiDokumenByToken = createServerFn({ method: "POST" })
  .inputValidator((i: unknown) => z.object({ token: z.string().min(8).max(128) }).parse(i))
  .handler(async ({ data }) => {
    const sb = await getAdmin();
    const { data: row } = await sb.from("bukti_dokumen")
      .select("id,kind,entity_id,nomor,status,signer_name,signer_position,signer_nip,revoked_at,revoked_reason,snapshot,created_at,opd_id,hash")
      .eq("token", data.token)
      .maybeSingle();
    if (!row) return { valid: false as const, reason: "not_found" as const };
    const { data: opd } = row.opd_id
      ? await sb.from("opd").select("nama,singkatan").eq("id", row.opd_id).maybeSingle()
      : { data: null };
    return {
      valid: (row.status === "active") as boolean,
      reason: row.status === "revoked" ? ("revoked" as const) : ("ok" as const),
      bukti: {
        id: row.id,
        kind: row.kind as BuktiKind,
        nomor: row.nomor,
        status: row.status as "active" | "revoked",
        revoked_at: row.revoked_at,
        revoked_reason: row.revoked_reason,
        signer_name: row.signer_name,
        signer_position: row.signer_position,
        signer_nip: row.signer_nip,
        created_at: row.created_at,
        opd: { nama: opd?.nama ?? "-", singkatan: opd?.singkatan ?? "-" },
        snapshot_json: row.snapshot ? JSON.stringify(row.snapshot) : null,
        hash: row.hash,
      },
    };
  });

// PUBLIC — verifikasi PDF via unggahan (server menghitung SHA-256).
export const verifyUploadedBukti = createServerFn({ method: "POST" })
  .inputValidator((i: unknown) =>
    z.object({
      token: z.string().min(8).max(128).optional(),
      pdfBase64: z.string().min(10),
    }).parse(i),
  )
  .handler(async ({ data }) => {
    const sb = await getAdmin();
    // Decode base64 → bytes.
    let bytes: Uint8Array;
    try {
      const bin = atob(data.pdfBase64);
      bytes = Uint8Array.from(bin, (c) => c.charCodeAt(0));
    } catch {
      return { match: false, reason: "bad_upload" as const };
    }
    if (bytes.byteLength > 20 * 1024 * 1024) {
      return { match: false, reason: "too_large" as const };
    }
    const h = await sha256Hex(bytes);
    type Row = { hash: string; status: string; created_at: string; token: string };
    let row: Row | null;
    if (data.token) {
      const q = await sb.from("bukti_dokumen")
        .select("hash,status,created_at,token")
        .eq("token", data.token)
        .maybeSingle();
      row = (q.data as Row | null) ?? null;
      if (!row) return { match: false, reason: "not_found" as const };
      if (h !== row.hash) return { match: false, reason: "mismatch" as const };
    } else {
      const q = await sb.from("bukti_dokumen")
        .select("hash,status,created_at,token")
        .eq("hash", h)
        .maybeSingle();
      row = (q.data as Row | null) ?? null;
      if (!row) return { match: false, reason: "mismatch" as const };
    }
    const r: Row = row;
    if (r.status === "revoked") return { match: true, reason: "revoked" as const, signed_at: r.created_at, token: r.token };
    return { match: true, reason: "ok" as const, signed_at: r.created_at, token: r.token };
  });

// PUBLIC — verifikasi hanya berdasarkan SHA-256 hash (tanpa upload).
export const verifyBuktiByHash = createServerFn({ method: "POST" })
  .inputValidator((i: unknown) =>
    z.object({
      hash: z.string().regex(/^[a-f0-9]{64}$/i),
      token: z.string().min(8).max(128).optional(),
    }).parse(i),
  )
  .handler(async ({ data }) => {
    const sb = await getAdmin();
    const h = data.hash.toLowerCase();
    const q = sb.from("bukti_dokumen").select("hash,status,created_at,token").eq("hash", h);
    const { data: row } = data.token
      ? await q.eq("token", data.token).maybeSingle()
      : await q.maybeSingle();
    if (!row) return { match: false, reason: "not_found" as const };
    if (row.status === "revoked") return { match: true, reason: "revoked" as const, signed_at: row.created_at, token: row.token };
    return { match: true, reason: "ok" as const, signed_at: row.created_at, token: row.token };
  });

export const revokeBukti = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) =>
    z.object({
      id: z.string().uuid(),
      reason: z.string().max(500).optional(),
    }).parse(i),
  )
  .handler(async ({ data, context }) => {
    const sb = await getAdmin();
    const { data: isSuper } = await sb.rpc("has_role", { _user_id: context.userId, _role: "super_admin" });
    const { data: isAdmin } = await sb.rpc("has_role", { _user_id: context.userId, _role: "admin_opd" });
    if (!isSuper && !isAdmin) throw new Error("Forbidden");
    const { error } = await sb.from("bukti_dokumen").update({
      status: "revoked",
      revoked_at: new Date().toISOString(),
      revoked_by: context.userId,
      revoked_reason: data.reason ?? null,
    }).eq("id", data.id);
    if (error) throw new Error(error.message);
    return { ok: true as const };
  });
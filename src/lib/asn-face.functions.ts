// Server functions biometrik wajah terpusat (server-side face matching)
// dan penugasan Work From Anywhere.
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";

type Ctx = {
  userId: string;
  supabase: {
    rpc: (
      fn: string,
      args: Record<string, unknown>,
    ) => PromiseLike<{ data: unknown; error: unknown }>;
  };
};

async function assertCanManage(context: Ctx, targetUserId?: string) {
  const sb = context.supabase;
  const { data: isSuper } = await sb.rpc("has_role", {
    _user_id: context.userId,
    _role: "super_admin",
  });
  if (isSuper) return { scopeOpd: null as string | null };
  const { data: isOpd } = await sb.rpc("has_role", {
    _user_id: context.userId,
    _role: "admin_opd",
  });
  if (!isOpd) throw new Error("Hanya Admin OPD atau Super Admin yang dapat merekam wajah ASN.");
  const { data: myOpd } = await sb.rpc("get_user_opd", { _user_id: context.userId });
  if (!myOpd) throw new Error("Akun Admin OPD Anda belum terhubung ke OPD.");
  if (targetUserId) {
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { data: p } = await supabaseAdmin
      .from("profiles")
      .select("opd_id")
      .eq("id", targetUserId)
      .maybeSingle();
    if (!p || p.opd_id !== myOpd) throw new Error("ASN ini bukan pegawai OPD Anda.");
  }
  return { scopeOpd: myOpd as string };
}

const photo = z.string().min(100).max(4_000_000);

// ============= STATUS WAJAH SAYA (ASN) =============
export const myFaceStatus = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { getFaceTemplate, activeWfa, MIN_FACE_SAMPLES } = await import("@/lib/asn-face.server");
    const tpl = await getFaceTemplate(context.userId);
    const wfa = await activeWfa(context.userId);
    return {
      enrolled: !!tpl,
      samples: tpl?.samples ?? 0,
      quality: tpl?.quality ?? null,
      adapt_count: tpl?.adapt_count ?? 0,
      updated_at: tpl?.updated_at ?? null,
      min: MIN_FACE_SAMPLES,
      wfa,
    };
  });

// ============= ADMIN: DAFTAR STATUS WAJAH ASN =============
export const adminListAsnFace = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { scopeOpd } = await assertCanManage(context as unknown as Ctx);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { MIN_FACE_SAMPLES } = await import("@/lib/asn-face.server");
    const { data: roles } = await supabaseAdmin
      .from("user_roles")
      .select("user_id")
      .eq("role", "asn");
    const ids = [...new Set((roles ?? []).map((r) => r.user_id))];
    if (ids.length === 0) return { rows: [], min: MIN_FACE_SAMPLES };
    let q = supabaseAdmin.from("profiles").select("id,nama_lengkap,nip,opd_id").in("id", ids);
    if (scopeOpd) q = q.eq("opd_id", scopeOpd);
    const { data: profs, error } = await q.order("nama_lengkap");
    if (error) throw new Error(error.message);
    const pids = (profs ?? []).map((p) => p.id);
    const { data: tpls } = pids.length
      ? await supabaseAdmin
          .from("asn_face_template")
          .select("user_id,samples,quality,adapt_count,updated_at")
          .in("user_id", pids)
      : { data: [] };
    const today = new Date().toISOString().slice(0, 10);
    const { data: wfas } = pids.length
      ? await supabaseAdmin
          .from("asn_wfa_assignment")
          .select("id,user_id,mulai,selesai,alasan,nomor_surat,status")
          .in("user_id", pids)
          .eq("status", "approved")
          .gte("selesai", today)
      : { data: [] };
    const rows = (profs ?? []).map((p) => ({
      ...p,
      face: (tpls ?? []).find((t) => t.user_id === p.id) ?? null,
      wfa: (wfas ?? []).filter((w) => w.user_id === p.id),
    }));
    return { rows, min: MIN_FACE_SAMPLES };
  });

// ============= ADMIN: REKAM WAJAH ASN =============
export const adminEnrollAsnFace = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) =>
    z
      .object({ target_user_id: z.string().uuid(), photos: z.array(photo).min(3).max(5) })
      .parse(i),
  )
  .handler(async ({ data, context }) => {
    await assertCanManage(context as unknown as Ctx, data.target_user_id);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { enrollFace } = await import("@/lib/asn-face.server");
    const { data: p } = await supabaseAdmin
      .from("profiles")
      .select("opd_id")
      .eq("id", data.target_user_id)
      .maybeSingle();
    return enrollFace({
      userId: data.target_user_id,
      opdId: (p?.opd_id as string | null) ?? null,
      photos: data.photos,
      enrolledBy: context.userId,
    });
  });

// ============= ADMIN: HAPUS REKAMAN WAJAH =============
export const adminDeleteAsnFace = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => z.object({ target_user_id: z.string().uuid() }).parse(i))
  .handler(async ({ data, context }) => {
    await assertCanManage(context as unknown as Ctx, data.target_user_id);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { error } = await supabaseAdmin
      .from("asn_face_template")
      .delete()
      .eq("user_id", data.target_user_id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

// ============= ADMIN: PENUGASAN WFA =============
export const adminCreateWfa = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) =>
    z
      .object({
        target_user_id: z.string().uuid(),
        mulai: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
        selesai: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
        alasan: z.string().max(300).optional().nullable(),
        nomor_surat: z.string().max(120).optional().nullable(),
      })
      .parse(i),
  )
  .handler(async ({ data, context }) => {
    await assertCanManage(context as unknown as Ctx, data.target_user_id);
    if (data.selesai < data.mulai) throw new Error("Tanggal selesai harus setelah tanggal mulai.");
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { data: p } = await supabaseAdmin
      .from("profiles")
      .select("opd_id")
      .eq("id", data.target_user_id)
      .maybeSingle();
    const { error } = await supabaseAdmin.from("asn_wfa_assignment").insert({
      user_id: data.target_user_id,
      opd_id: (p?.opd_id as string | null) ?? null,
      mulai: data.mulai,
      selesai: data.selesai,
      alasan: data.alasan ?? null,
      nomor_surat: data.nomor_surat ?? null,
      status: "approved",
      created_by: context.userId,
    });
    if (error) throw new Error(error.message);
    return { ok: true };
  });

export const adminDeleteWfa = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) =>
    z.object({ target_user_id: z.string().uuid(), id: z.string().uuid() }).parse(i),
  )
  .handler(async ({ data, context }) => {
    await assertCanManage(context as unknown as Ctx, data.target_user_id);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { error } = await supabaseAdmin
      .from("asn_wfa_assignment")
      .delete()
      .eq("id", data.id)
      .eq("user_id", data.target_user_id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

// Server functions biometrik ASN (WebAuthn / FIDO2).
// Pendaftaran sidik jari HANYA oleh Admin OPD (untuk ASN di OPD-nya) dan Super Admin.
// ASN sendiri hanya dapat melihat status & memverifikasi saat absen.
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";

type Ctx = {
  userId: string;
  supabase: {
    rpc: (fn: string, args: Record<string, unknown>) => PromiseLike<{ data: unknown; error: unknown }>;
  };
};

/** Periksa hak admin atas ASN target. Super Admin: semua; Admin OPD: ASN di OPD-nya. */
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
  if (!isOpd) throw new Error("Hanya Admin OPD atau Super Admin yang dapat mendaftarkan sidik jari.");
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

const targetSchema = z.object({ target_user_id: z.string().uuid() });

// ============= STATUS SIDIK JARI SAYA (ASN) =============
export const listBiometricCredentials = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { listEnrolledDevices, MIN_FINGERS } = await import("@/lib/asn-biometric.server");
    const rows = await listEnrolledDevices(context.userId);
    return { rows, enrolled: rows.length >= MIN_FINGERS, min: MIN_FINGERS };
  });

// ============= ADMIN: DAFTAR ASN + JUMLAH JARI =============
export const adminListAsnBiometric = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { scopeOpd } = await assertCanManage(context as unknown as Ctx);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { MIN_FINGERS } = await import("@/lib/asn-biometric.server");
    const { data: roles } = await supabaseAdmin.from("user_roles").select("user_id").eq("role", "asn");
    const ids = [...new Set((roles ?? []).map((r) => r.user_id))];
    if (ids.length === 0) return { rows: [], min: MIN_FINGERS };
    let q = supabaseAdmin.from("profiles").select("id,nama_lengkap,nip,opd_id").in("id", ids);
    if (scopeOpd) q = q.eq("opd_id", scopeOpd);
    const { data: profs, error } = await q.order("nama_lengkap");
    if (error) throw new Error(error.message);
    const pids = (profs ?? []).map((p) => p.id);
    const { data: creds } = pids.length
      ? await supabaseAdmin
          .from("asn_webauthn_credential")
          .select("id,user_id,finger_label,device_label,created_at")
          .in("user_id", pids)
          .eq("aktif", true)
          .order("created_at")
      : { data: [] };
    const rows = (profs ?? []).map((p) => ({
      ...p,
      fingers: (creds ?? []).filter((c) => c.user_id === p.id),
    }));
    return { rows, min: MIN_FINGERS };
  });

// ============= ADMIN: MULAI REKAM JARI =============
export const adminStartBiometricRegistration = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => targetSchema.parse(i))
  .handler(async ({ data, context }) => {
    await assertCanManage(context as unknown as Ctx, data.target_user_id);
    const { buildRegistrationOptions } = await import("@/lib/asn-biometric.server");
    return { options: await buildRegistrationOptions(data.target_user_id) };
  });

// ============= ADMIN: SIMPAN REKAMAN JARI =============
export const adminFinishBiometricRegistration = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) =>
    targetSchema
      .extend({
        response: z.record(z.unknown()),
        finger_label: z.string().min(1).max(60),
        device_label: z.string().max(120).optional().nullable(),
      })
      .parse(i),
  )
  .handler(async ({ data, context }) => {
    await assertCanManage(context as unknown as Ctx, data.target_user_id);
    const { completeRegistration } = await import("@/lib/asn-biometric.server");
    return completeRegistration(data.target_user_id, data.response, data.device_label ?? null, {
      fingerLabel: data.finger_label,
      enrolledBy: context.userId,
    });
  });

// ============= ADMIN: HAPUS REKAMAN JARI =============
export const adminDeleteBiometricCredential = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => targetSchema.extend({ id: z.string().uuid() }).parse(i))
  .handler(async ({ data, context }) => {
    await assertCanManage(context as unknown as Ctx, data.target_user_id);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { error } = await supabaseAdmin
      .from("asn_webauthn_credential")
      .delete()
      .eq("id", data.id)
      .eq("user_id", data.target_user_id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

// ============= MULAI VERIFIKASI (SAAT ABSEN) =============
export const startBiometricAssertion = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { buildAuthenticationOptions } = await import("@/lib/asn-biometric.server");
    return { options: await buildAuthenticationOptions(context.userId) };
  });

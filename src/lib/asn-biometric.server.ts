// Helper server-only untuk biometrik ASN (WebAuthn / FIDO2).
// Tidak boleh diimpor dari komponen — hanya dari handler server function.
import { getRequest } from "@tanstack/react-start/server";
import { supabaseAdmin } from "@/integrations/supabase/client.server";
import {
  generateRegistrationOptions,
  verifyRegistrationResponse,
  generateAuthenticationOptions,
  verifyAuthenticationResponse,
} from "@simplewebauthn/server";
import { isoBase64URL, isoUint8Array } from "@simplewebauthn/server/helpers";

export const RP_NAME = "Absensi ASN";
/** Minimal jumlah jari terdaftar (oleh admin) sebelum verifikasi sidik jari berlaku. */
export const MIN_FINGERS = 3;

type Transports = AuthenticatorTransport[] | undefined;

/** Origin & rpID diturunkan dari permintaan aktual (preview / domain resmi). */
export function resolveRp() {
  const req = getRequest();
  const originHeader = req.headers.get("origin");
  const url = new URL(originHeader ?? req.url);
  return { origin: url.origin, rpID: url.hostname };
}

async function storeChallenge(userId: string, challenge: string, tujuan: string) {
  await supabaseAdmin
    .from("asn_webauthn_challenge")
    .delete()
    .eq("user_id", userId)
    .eq("tujuan", tujuan);
  const { error } = await supabaseAdmin.from("asn_webauthn_challenge").insert({
    user_id: userId,
    challenge,
    tujuan,
    expires_at: new Date(Date.now() + 5 * 60_000).toISOString(),
  });
  if (error) throw new Error(error.message);
}

/** Ambil challenge yang masih berlaku lalu hapus (sekali pakai). */
async function consumeChallenge(userId: string, tujuan: string): Promise<string> {
  const { data, error } = await supabaseAdmin
    .from("asn_webauthn_challenge")
    .select("id,challenge,expires_at")
    .eq("user_id", userId)
    .eq("tujuan", tujuan)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) throw new Error("Sesi verifikasi biometrik tidak ditemukan. Ulangi prosesnya.");
  await supabaseAdmin.from("asn_webauthn_challenge").delete().eq("id", data.id);
  if (new Date(data.expires_at).getTime() < Date.now())
    throw new Error("Sesi verifikasi biometrik kedaluwarsa. Ulangi prosesnya.");
  return data.challenge;
}

type CredRow = {
  id: string;
  credential_id: string;
  public_key: string;
  counter: number;
  transports: string[] | null;
};

async function listCredRows(userId: string): Promise<CredRow[]> {
  const { data, error } = await supabaseAdmin
    .from("asn_webauthn_credential")
    .select("id,credential_id,public_key,counter,transports")
    .eq("user_id", userId)
    .eq("aktif", true);
  if (error) throw new Error(error.message);
  return (data ?? []) as CredRow[];
}

export async function listEnrolledDevices(userId: string) {
  const { data, error } = await supabaseAdmin
    .from("asn_webauthn_credential")
    .select("id,device_label,finger_label,enrolled_by,created_at,last_used_at")
    .eq("user_id", userId)
    .eq("aktif", true)
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);
  return data ?? [];
}

export async function hasBiometricEnrolled(userId: string): Promise<boolean> {
  const { count, error } = await supabaseAdmin
    .from("asn_webauthn_credential")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("aktif", true);
  if (error) return false;
  return (count ?? 0) >= MIN_FINGERS;
}

export async function buildRegistrationOptions(userId: string) {
  const { rpID } = resolveRp();
    const { data: profile } = await supabaseAdmin
    .from("profiles")
    .select("nama_lengkap,nip,username")
    .eq("id", userId)
    .maybeSingle();
  const userName = profile?.nip || profile?.username || profile?.nama_lengkap || "ASN";

  const options = await generateRegistrationOptions({
    rpName: RP_NAME,
    rpID,
    userID: isoUint8Array.fromUTF8String(userId),
    userName,
    userDisplayName: profile?.nama_lengkap ?? userName,
    attestationType: "none",
    authenticatorSelection: {
      // Wajib sensor bawaan perangkat (sidik jari / Face ID), bukan kunci eksternal.
      authenticatorAttachment: "platform",
      // Non-discoverable: memungkinkan beberapa jari (kredensial) untuk ASN yang sama.
      residentKey: "discouraged",
      userVerification: "required",
    },
  });
  await storeChallenge(userId, options.challenge, "register");
  return options;
}

export async function completeRegistration(
  userId: string,
  response: Record<string, unknown>,
  deviceLabel: string | null,
  extra: { fingerLabel?: string | null; enrolledBy?: string | null } = {},
) {
  const { origin, rpID } = resolveRp();
  const expectedChallenge = await consumeChallenge(userId, "register");
  const verification = await verifyRegistrationResponse({
    response: response as never,
    expectedChallenge,
    expectedOrigin: origin,
    expectedRPID: rpID,
    requireUserVerification: true,
  });
  if (!verification.verified || !verification.registrationInfo)
    throw new Error("Pendaftaran sidik jari gagal diverifikasi.");

  const cred = verification.registrationInfo.credential;
  const { error } = await supabaseAdmin.from("asn_webauthn_credential").insert({
    user_id: userId,
    credential_id: cred.id,
    public_key: isoBase64URL.fromBuffer(cred.publicKey),
    counter: cred.counter,
    transports: cred.transports ?? null,
    device_label: deviceLabel?.slice(0, 120) ?? null,
    finger_label: extra.fingerLabel?.slice(0, 60) ?? null,
    enrolled_by: extra.enrolledBy ?? null,
  });
  if (error) throw new Error(error.message);
  return { ok: true as const };
}

export async function buildAuthenticationOptions(userId: string) {
  const { rpID } = resolveRp();
  const creds = await listCredRows(userId);
  if (creds.length < MIN_FINGERS)
    throw new Error(`Sidik jari belum lengkap (minimal ${MIN_FINGERS} jari). Hubungi Admin OPD.`);
  const options = await generateAuthenticationOptions({
    rpID,
    allowCredentials: creds.map((c) => ({
      id: c.credential_id,
      transports: (c.transports ?? undefined) as Transports,
    })),
    userVerification: "required",
  });
  await storeChallenge(userId, options.challenge, "authenticate");
  return options;
}

/** Verifikasi assertion biometrik; dipakai submitAbsensi sebelum absensi sah. */
export async function verifyBiometricAssertion(
  userId: string,
  response: Record<string, unknown>,
): Promise<{ credentialId: string }> {
  const { origin, rpID } = resolveRp();
  const expectedChallenge = await consumeChallenge(userId, "authenticate");
  const rawId = String((response as { id?: string }).id ?? "");
  const creds = await listCredRows(userId);
  const match = creds.find((c) => c.credential_id === rawId);
  if (!match) throw new Error("Sidik jari ini belum terdaftar untuk akun Anda.");

  const verification = await verifyAuthenticationResponse({
    response: response as never,
    expectedChallenge,
    expectedOrigin: origin,
    expectedRPID: rpID,
    requireUserVerification: true,
    credential: {
      id: match.credential_id,
      publicKey: isoBase64URL.toBuffer(match.public_key),
      counter: Number(match.counter ?? 0),
      transports: (match.transports ?? undefined) as Transports,
    },
  });
  if (!verification.verified) throw new Error("Verifikasi sidik jari gagal.");

  await supabaseAdmin
    .from("asn_webauthn_credential")
    .update({
      counter: verification.authenticationInfo.newCounter,
      last_used_at: new Date().toISOString(),
    })
    .eq("id", match.id);

  return { credentialId: match.credential_id };
}

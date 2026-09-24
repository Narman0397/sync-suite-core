// Modul ASN: Kantor QR + Absensi.
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";
import { supabaseAdmin } from "@/integrations/supabase/client.server";
import { checkRateLimit } from "@/integrations/supabase/rate-limit.server";
import { getUserContext } from "@/features/rbac/guards";

// Shim back-compat: pertahankan shape lama yang dipakai handler di bawah.
async function userRolesAndOpd(userId: string) {
  const ctx = await getUserContext(supabaseAdmin, userId);
  return { isSuper: ctx.isSuper, isAdminOpd: ctx.isAdminOpd, isAsn: ctx.isAsn, opdId: ctx.opdId };
}

function randomToken(bytes = 24) {
  const arr = new Uint8Array(bytes);
  crypto.getRandomValues(arr);
  return Array.from(arr, (b) => b.toString(16).padStart(2, "0")).join("");
}

// Haversine distance in meters
function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number) {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

export const regenerateKantorQR = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) =>
    z
      .object({
        opd_id: z.string().uuid(),
        label: z.string().max(120).optional(),
        lokasi: z.string().max(255).optional(),
        lat: z.number().min(-90).max(90).optional().nullable(),
        lng: z.number().min(-180).max(180).optional().nullable(),
        radius_m: z.number().int().min(10).max(5000).optional(),
        rotate: z.boolean().optional(),
      })
      .parse(input),
  )
  .handler(async ({ data, context }) => {
    const { userId } = context;
    const ctx = await userRolesAndOpd(userId);
    if (!(ctx.isSuper || (ctx.isAdminOpd && ctx.opdId === data.opd_id))) {
      throw new Error("Forbidden");
    }
    const rl = await checkRateLimit(userId, "qr_regen", 20, 60);
    if (!rl.ok) throw new Error("Terlalu banyak permintaan");

    const { data: existing } = await supabaseAdmin
      .from("kantor_qr")
      .select("id,token")
      .eq("opd_id", data.opd_id)
      .maybeSingle();
    const token = existing && !data.rotate ? existing.token : randomToken(24);
    const patch = {
      token,
      aktif: true,
      ...(data.label !== undefined ? { label: data.label ?? null } : {}),
      ...(data.lokasi !== undefined ? { lokasi: data.lokasi ?? null } : {}),
      ...(data.lat !== undefined ? { lat: data.lat } : {}),
      ...(data.lng !== undefined ? { lng: data.lng } : {}),
      ...(data.radius_m !== undefined ? { radius_m: data.radius_m } : {}),
    };

    if (existing) {
      const { error } = await supabaseAdmin.from("kantor_qr").update(patch).eq("id", existing.id);
      if (error) throw new Error(error.message);
    } else {
      const { error } = await supabaseAdmin
        .from("kantor_qr")
        .insert({ opd_id: data.opd_id, ...patch });
      if (error) throw new Error(error.message);
    }

    return { ok: true, token };
  });

// ============= LIST KANTOR QR (super admin) =============
export const listKantorQR = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const ctx = await userRolesAndOpd(context.userId);
    if (!ctx.isSuper) throw new Error("Forbidden");
    const { data, error } = await supabaseAdmin
      .from("kantor_qr")
      .select(
        "id,opd_id,token,label,lokasi,lat,lng,radius_m,aktif,updated_at, opd:opd!opd_id(nama,singkatan)",
      );
    if (error) throw new Error(error.message);
    return { rows: data ?? [] };
  });

// ============= RESOLVE QR TOKEN =============
export const resolveKantorQR = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => z.object({ token: z.string().min(8).max(80) }).parse(input))
  .handler(async ({ data }) => {
    const { data: row, error } = await supabaseAdmin
      .from("kantor_qr")
      .select("id,opd_id,label,lokasi,lat,lng,radius_m,aktif, opd:opd!opd_id(nama,singkatan)")
      .eq("token", data.token)
      .maybeSingle();
    if (error) throw new Error(error.message);
    if (!row || !row.aktif) throw new Error("QR tidak valid / nonaktif");
    return row;
  });

// ============= SUBMIT ABSENSI =============
export const submitAbsensi = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) =>
    z
      .object({
        token: z.string().min(8).max(80).optional().nullable(),
        mode: z.enum(["wfo", "wfa"]).default("wfo"),
        tipe: z.enum(["masuk", "pulang"]),
        lat: z.number(),
        lng: z.number(),
        device_info: z.string().max(200).optional().nullable(),
        device_fingerprint: z.string().max(200).optional().nullable(),
        foto_base64: z.string().min(100).max(8_000_000), // wajib — anti titip-absen
        biometric_response: z.record(z.unknown()).optional().nullable(), // assertion WebAuthn
        liveness_score: z.number().min(0).max(255).optional().nullable(),
      })
      .parse(input),
  )
  .handler(async ({ data, context }) => {
    const { userId } = context;
    const rl = await checkRateLimit(userId, "absensi", 10, 60);
    if (!rl.ok) throw new Error("Terlalu banyak percobaan absen");

    const ctx = await userRolesAndOpd(userId);
    if (!ctx.isAsn) throw new Error("Hanya ASN terdaftar yang dapat absen");
    if (!ctx.opdId) throw new Error("Profil Anda belum terhubung ke OPD");

    // Verifikasi biometrik (sidik jari / Face ID perangkat) — wajib bila ASN
    // sudah mendaftarkan biometrik. Anti titip-absen lapis keempat.
    const { hasBiometricEnrolled, verifyBiometricAssertion } = await import(
      "@/lib/asn-biometric.server"
    );
    const biometricEnrolled = await hasBiometricEnrolled(userId);
    let biometricCredentialId: string | null = null;
    if (biometricEnrolled) {
      if (!data.biometric_response)
        throw new Error("Verifikasi sidik jari wajib. Ulangi absen dan tempelkan sidik jari Anda.");
      const res = await verifyBiometricAssertion(userId, data.biometric_response);
      biometricCredentialId = res.credentialId;
    } else if (data.biometric_response) {
      throw new Error("Sidik jari belum terdaftar pada akun ini.");
    }

    // Verifikasi wajah terpusat di server (pencocokan vektor biometrik di DB).
    const { verifyFace, activeWfa } = await import("@/lib/asn-face.server");
    const face = await verifyFace(userId, data.foto_base64);
    const { LIVENESS_MIN, FACE_FUSION_MARGIN } = await import("@/lib/face-embedding.server");
    if (face.outdated)
      throw new Error("Rekaman wajah Anda perlu diperbarui. Temui Admin OPD untuk rekam ulang wajah.");
    if (face.enrolled && data.liveness_score != null && data.liveness_score < LIVENESS_MIN)
      throw new Error(
        "Wajah tidak terdeteksi sebagai wajah asli. Jangan gunakan foto/layar, lalu ulangi pemindaian.",
      );
    // Fusi kontekstual: skor sedikit di bawah ambang boleh diterima bila ASN
    // berada dalam radius kantor (WFO) dan memakai perangkat yang sebelumnya
    // pernah lolos verifikasi wajah.
    let faceDecision: "match" | "fusion" | "none" = face.verified ? "match" : "none";
    const nearMiss =
      face.enrolled &&
      !face.verified &&
      face.score !== null &&
      face.score >= face.threshold - FACE_FUSION_MARGIN;
    if (face.enrolled && !face.verified && !(nearMiss && data.mode === "wfo"))
      throw new Error(
        "Wajah tidak cocok dengan data yang terekam. Pastikan pencahayaan cukup dan wajah menghadap kamera.",
      );

    const isWfa = data.mode === "wfa";
    let qr: { opd_id: string };
    let wfaReason: string | null = null;

    if (isWfa) {
      const w = await activeWfa(userId);
      if (!w)
        throw new Error(
          "Anda belum memiliki penugasan Work From Anywhere yang aktif hari ini. Hubungi Admin OPD.",
        );
      if (!face.enrolled)
        throw new Error(
          "Absen dari luar kantor memerlukan rekaman wajah. Temui Admin OPD untuk perekaman wajah.",
        );
      qr = { opd_id: ctx.opdId };
      wfaReason = w.alasan ?? w.nomor_surat ?? "Penugasan WFA";
      await supabaseAdmin.from("geofence_audit").insert({
        user_id: userId,
        opd_id: ctx.opdId,
        lat: data.lat,
        lng: data.lng,
        dist_m: 0,
        radius_m: 0,
        valid: true,
        reason: "wfa",
      });
    } else {
      const { data: qrRow, error: qErr } = await supabaseAdmin
        .from("kantor_qr")
        .select("opd_id,aktif,lat,lng,radius_m")
        .eq("token", data.token ?? "")
        .maybeSingle();
      if (qErr) throw new Error(qErr.message);
      if (!qrRow || !qrRow.aktif) throw new Error("QR tidak valid");
      if (qrRow.opd_id !== ctx.opdId) throw new Error("QR ini bukan untuk kantor OPD Anda");
      qr = { opd_id: qrRow.opd_id as string };

      if (qrRow.lat !== null && qrRow.lng !== null) {
        const radius = (qrRow.radius_m as number | null) ?? 100;
        const dist = haversineMeters(Number(qrRow.lat), Number(qrRow.lng), data.lat, data.lng);
        const valid = dist <= radius;
        await supabaseAdmin.from("geofence_audit").insert({
          user_id: userId,
          opd_id: qrRow.opd_id,
          lat: data.lat,
          lng: data.lng,
          dist_m: Math.round(dist),
          radius_m: radius,
          valid,
          reason: valid ? null : `out_of_range ${Math.round(dist)}m`,
        });
        if (!valid) {
          throw new Error(
            `Absen gagal. Anda berada ${Math.round(dist)} m dari kantor (maks ${radius} m). Mendekatlah ke titik kantor lalu coba lagi.`,
          );
        }
      } else {
        throw new Error("Koordinat kantor belum ditetapkan superadmin. Hubungi admin.");
      }
    }

    if (nearMiss && faceDecision === "none") {
      const fp = data.device_fingerprint?.slice(0, 200) ?? "";
      const { data: trusted } = fp
        ? await supabaseAdmin
            .from("absensi_asn")
            .select("id")
            .eq("user_id", userId)
            .eq("device_fingerprint_hash", fp)
            .eq("face_verified", true)
            .limit(1)
        : { data: [] };
      if (!trusted?.length)
        throw new Error(
          "Wajah tidak cocok dengan data yang terekam. Pastikan pencahayaan cukup dan wajah menghadap kamera.",
        );
      faceDecision = "fusion";
    }
    const faceOk = faceDecision !== "none";

    // Cegah duplikat masuk/pulang di hari yang sama
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    const { data: dup } = await supabaseAdmin
      .from("absensi_asn")
      .select("id")
      .eq("user_id", userId)
      .eq("opd_id", qr.opd_id)
      .eq("tipe", data.tipe)
      .gte("waktu", today.toISOString())
      .maybeSingle();
    if (dup) throw new Error(`Anda sudah absen ${data.tipe} hari ini`);

    // Resolve jadwal: prioritas shift_assignment hari ini, fallback work_schedule_assignment
    const tglStr = new Date().toISOString().slice(0, 10);
    let scheduleId: string | null = null;
    let jamMasuk: string | null = null;
    let toleransi = 15;
    let sumberJadwal: "shift" | "schedule" | null = null;

    const { data: shiftRows } = await supabaseAdmin
      .from("attendance_shift_assignment")
      .select("dari, sampai, shift:attendance_shifts!shift_id(id,jam_masuk,toleransi_menit,aktif)")
      .eq("user_id", userId)
      .lte("dari", tglStr)
      .order("dari", { ascending: false })
      .limit(10);
    type Shift = {
      id: string;
      jam_masuk: string;
      toleransi_menit: number | null;
      aktif: boolean;
    } | null;
    const shiftMatch = (shiftRows ?? []).find((r) => !r.sampai || r.sampai >= tglStr);
    const shift = (shiftMatch?.shift as unknown as Shift) ?? null;
    if (shift && shift.aktif) {
      scheduleId = shift.id;
      jamMasuk = shift.jam_masuk;
      toleransi = shift.toleransi_menit ?? 15;
      sumberJadwal = "shift";
    } else {
      const { data: wsa } = await supabaseAdmin
        .from("work_schedule_assignment")
        .select(
          "schedule_id, berlaku_dari, berlaku_sampai, schedule:work_schedule!schedule_id(jam_masuk,toleransi_menit,hari_kerja,aktif)",
        )
        .eq("user_id", userId)
        .lte("berlaku_dari", tglStr)
        .order("berlaku_dari", { ascending: false })
        .limit(5);
      const ws = (wsa ?? []).find((r) => !r.berlaku_sampai || r.berlaku_sampai >= tglStr);
      type Sch = { jam_masuk: string; toleransi_menit: number; aktif: boolean } | null;
      const sch = (ws?.schedule as unknown as Sch) ?? null;
      if (ws && sch && sch.aktif) {
        scheduleId = ws.schedule_id;
        jamMasuk = sch.jam_masuk;
        toleransi = sch.toleransi_menit ?? 15;
        sumberJadwal = "schedule";
      }
    }

    let isLate = false;
    let lateMin = 0;
    if (jamMasuk && data.tipe === "masuk") {
      const [hh, mm] = jamMasuk.split(":").map((n) => parseInt(n, 10));
      const sched = new Date();
      sched.setHours(hh, mm, 0, 0);
      const deadline = new Date(sched.getTime() + toleransi * 60_000);
      const now = new Date();
      if (now > deadline) {
        isLate = true;
        lateMin = Math.round((now.getTime() - sched.getTime()) / 60_000);
      }
    }

    // Upload foto wajib ke bucket private absensi-foto/{userId}/{yyyy-mm-dd}/{tipe}-{ts}.jpg
    const m = data.foto_base64.match(/^data:(image\/[a-z+]+);base64,(.+)$/i);
    if (!m) throw new Error("Format foto tidak valid (harus data URL image/*)");
    const mime = m[1];
    if (!/^image\/(jpeg|jpg|png|webp)$/i.test(mime))
      throw new Error("Tipe gambar harus JPEG/PNG/WEBP");
    const bin = Buffer.from(m[2], "base64");
    if (bin.byteLength > 2_500_000) throw new Error("Ukuran foto maksimal 2.5 MB");
    const ext = mime.split("/")[1].replace("jpeg", "jpg");
    const fotoPath = `${userId}/${tglStr}/${data.tipe}-${Date.now()}.${ext}`;
    const { error: upErr } = await supabaseAdmin.storage
      .from("absensi-foto")
      .upload(fotoPath, bin, { contentType: mime, upsert: false });
    if (upErr) throw new Error(`Upload foto gagal: ${upErr.message}`);

    // Hash fingerprint client (sudah di-hash di sisi client) — server simpan apa adanya (max 200)
    const fpHash = data.device_fingerprint?.slice(0, 200) ?? null;

    const { FOTO_RETENTION_DAYS } = await import("@/lib/asn-face.server");
    const fotoExpiresAt = new Date(
      Date.now() + FOTO_RETENTION_DAYS * 86_400_000,
    ).toISOString();

    const { error: insErr } = await supabaseAdmin.from("absensi_asn").insert({
      user_id: userId,
      opd_id: qr.opd_id,
      tipe: data.tipe,
      lat: data.lat,
      lng: data.lng,
      device_info: data.device_info ?? null,
      device_fingerprint_hash: fpHash,
      foto_url: fotoPath,
      is_late: isLate,
      late_minutes: lateMin,
      schedule_id: scheduleId,
      biometric_verified: !!biometricCredentialId,
      biometric_credential_id: biometricCredentialId,
      mode: isWfa ? "wfa" : "qr",
      wfa_reason: wfaReason,
      face_verified: face.enrolled ? faceOk : false,
      face_score: face.score,
      foto_expires_at: fotoExpiresAt,
    });
    if (insErr) throw new Error(insErr.message);
    return {
      ok: true,
      is_late: isLate,
      late_minutes: lateMin,
      sumber_jadwal: sumberJadwal,
      biometric_verified: !!biometricCredentialId,
      mode: isWfa ? "wfa" : "qr",
      face_verified: face.enrolled ? faceOk : false,
      face_score: face.score,
      face_decision: faceDecision,
    };
  });

// ============= LIST ABSENSI =============
export const listAbsensiSelf = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { data, error } = await supabaseAdmin
      .from("absensi_asn")
      .select(
        "id,tipe,waktu,mode,wfa_reason,face_verified,biometric_verified,opd:opd!opd_id(nama,singkatan)",
      )
      .eq("user_id", context.userId)
      .order("waktu", { ascending: false })
      .limit(60);
    if (error) throw new Error(error.message);
    return { rows: data ?? [] };
  });

export const listAbsensiAdmin = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) =>
    z
      .object({
        opd_id: z.string().uuid().optional().nullable(),
        from: z.string().optional().nullable(),
        to: z.string().optional().nullable(),
      })
      .parse(input),
  )
  .handler(async ({ data, context }) => {
    const ctx = await userRolesAndOpd(context.userId);
    if (!ctx.isSuper && !ctx.isAdminOpd) throw new Error("Forbidden");
    let q = supabaseAdmin
      .from("absensi_asn")
      .select(
        "id,user_id,tipe,waktu,lat,lng,opd_id, opd:opd!opd_id(nama,singkatan), profile:profiles!user_id(nama_lengkap,nip,jabatan)",
      )
      .order("waktu", { ascending: false })
      .limit(500);
    const filterOpd = ctx.isSuper ? (data.opd_id ?? null) : ctx.opdId;
    if (filterOpd) q = q.eq("opd_id", filterOpd);
    if (data.from) q = q.gte("waktu", data.from);
    if (data.to) q = q.lte("waktu", data.to);
    const { data: rows, error } = await q;
    if (error) throw new Error(error.message);
    return { rows: rows ?? [] };
  });

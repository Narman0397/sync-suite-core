#!/usr/bin/env node
/**
 * Buat akun super_admin terverifikasi di project Supabase MANA PUN (mis. Supabase pribadi Anda).
 *
 * Pakai:
 *   SUPABASE_URL="https://xxxx.supabase.co" \
 *   SUPABASE_SERVICE_ROLE_KEY="<service role key>" \
 *   SA_EMAIL="admin@domain.com" \
 *   SA_PASSWORD="PasswordKuat123" \
 *   SA_USERNAME="superadmin" \
 *   SA_NAMA="Super Administrator" \
 *   node scripts/create-superadmin.mjs
 *
 * Idempoten: kalau email sudah ada, password & profil diperbarui, role dipastikan super_admin.
 */
import { createClient } from "@supabase/supabase-js";

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
const email = (process.env.SA_EMAIL || "").trim().toLowerCase();
const password = process.env.SA_PASSWORD || "";
const username = (process.env.SA_USERNAME || "superadmin").trim().toLowerCase();
const nama = process.env.SA_NAMA || "Super Administrator";

const missing = [
  !url && "SUPABASE_URL",
  !key && "SUPABASE_SERVICE_ROLE_KEY",
  !email && "SA_EMAIL",
  !password && "SA_PASSWORD",
].filter(Boolean);
if (missing.length) {
  console.error("Variabel wajib belum diisi: " + missing.join(", "));
  process.exit(1);
}
if (password.length < 8) {
  console.error("SA_PASSWORD minimal 8 karakter.");
  process.exit(1);
}

const admin = createClient(url, key, {
  auth: { persistSession: false, autoRefreshToken: false },
});

async function findUserByEmail(target) {
  for (let page = 1; page <= 20; page++) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 });
    if (error) throw new Error(error.message);
    const hit = data.users.find((u) => (u.email || "").toLowerCase() === target);
    if (hit) return hit;
    if (data.users.length < 200) return null;
  }
  return null;
}

const meta = { username, nama_lengkap: nama, requested_role: "super_admin" };

let user = await findUserByEmail(email);
if (user) {
  const { data, error } = await admin.auth.admin.updateUserById(user.id, {
    password,
    email_confirm: true,
    user_metadata: { ...(user.user_metadata || {}), ...meta },
  });
  if (error) throw new Error("Gagal memperbarui user: " + error.message);
  user = data.user;
  console.log("User sudah ada → password & verifikasi diperbarui:", user.id);
} else {
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: meta,
  });
  if (error) throw new Error("Gagal membuat user: " + error.message);
  user = data.user;
  console.log("User baru dibuat:", user.id);
}

const { error: pErr } = await admin.from("profiles").upsert(
  {
    id: user.id,
    username,
    nama_lengkap: nama,
    status: "active",
    verification_status: "verified",
    verified_at: new Date().toISOString(),
    verification_method: "manual_seed",
    requested_role: "super_admin",
  },
  { onConflict: "id" },
);
if (pErr) throw new Error("Gagal menulis profiles: " + pErr.message);

const { error: rErr } = await admin
  .from("user_roles")
  .upsert({ user_id: user.id, role: "super_admin" }, { onConflict: "user_id,role" });
if (rErr) throw new Error("Gagal menulis user_roles: " + rErr.message);

console.log(`Selesai. Login sebagai ${email} (username: ${username}) dengan role super_admin.`);

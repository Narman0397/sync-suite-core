// Pengumuman broadcast (announcements + announcement_targets).
// Pengumuman: CRUD + publish (auto-notif ke target).
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";
import { supabaseAdmin } from "@/integrations/supabase/client.server";
import { enqueueMany } from "./notifications.functions";
import { resolveUsersFromTargetRows } from "@/features/forms/services/assignment-resolution.service";
import { getUserContext } from "@/features/rbac/guards";

const PRIORITAS = z.enum(["info", "penting", "urgent"]);

const TargetSchema = z.object({
  target_type: z.enum(["role", "opd", "asn_type", "position", "individu", "unit_kerja"]),
  target_value: z.string().min(1),
});

const UpsertSchema = z.object({
  id: z.string().uuid().optional(),
  judul: z.string().trim().min(3).max(200),
  isi: z.string().trim().max(5000).default(""),
  prioritas: PRIORITAS.default("info"),
  link: z.string().trim().max(500).nullable().optional(),
  opd_pemilik_id: z.string().uuid().nullable().optional(),
  targets: z.array(TargetSchema).default([]),
});

async function assertCanManage(userId: string, opdPemilikId: string | null) {
  const ctx = await getUserContext(supabaseAdmin, userId);
  if (ctx.isElevated) return ctx;
  if (ctx.isAdminOpd && opdPemilikId && ctx.opdId === opdPemilikId) return ctx;
  throw new Error("Akses ditolak");
}

export const listAnnouncements = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) =>
    z
      .object({
        page: z.number().int().min(0).default(0),
        pageSize: z.number().int().min(1).max(50).default(20),
        status: z.enum(["all", "draft", "published"]).default("all"),
      })
      .parse(input ?? {}),
  )
  .handler(async ({ data }) => {
    let q = supabaseAdmin
      .from("announcements")
      .select("id,judul,prioritas,status,published_at,opd_pemilik_id,created_at,updated_at", {
        count: "exact",
      })
      .order("updated_at", { ascending: false })
      .range(data.page * data.pageSize, data.page * data.pageSize + data.pageSize - 1);
    if (data.status !== "all") q = q.eq("status", data.status);
    const { data: rows, count, error } = await q;
    if (error) throw new Error(error.message);
    return { rows: rows ?? [], total: count ?? 0 };
  });

export const getAnnouncement = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => z.object({ id: z.string().uuid() }).parse(input))
  .handler(async ({ data }) => {
    const { data: row, error } = await supabaseAdmin
      .from("announcements")
      .select("*")
      .eq("id", data.id)
      .maybeSingle();
    if (error) throw new Error(error.message);
    if (!row) throw new Error("Pengumuman tidak ditemukan");
    const { data: targets } = await supabaseAdmin
      .from("announcement_targets")
      .select("id,target_type,target_value")
      .eq("announcement_id", data.id);
    return { row, targets: targets ?? [] };
  });

export const upsertAnnouncement = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => UpsertSchema.parse(input))
  .handler(async ({ data, context }) => {
    const { userId } = context as { userId: string };
    const ctx = await assertCanManage(userId, data.opd_pemilik_id ?? null);
    // admin_opd terkunci di OPD sendiri.
    const opdFinal = ctx.isElevated
      ? (data.opd_pemilik_id ?? null)
      : (ctx.opdId ?? null);

    let id = data.id;
    if (id) {
      const { data: existing } = await supabaseAdmin
        .from("announcements")
        .select("id,opd_pemilik_id,status")
        .eq("id", id)
        .maybeSingle();
      if (!existing) throw new Error("Pengumuman tidak ditemukan");
      await assertCanManage(userId, existing.opd_pemilik_id);
      const { error } = await supabaseAdmin
        .from("announcements")
        .update({
          judul: data.judul,
          isi: data.isi,
          prioritas: data.prioritas,
          link: data.link ?? null,
          opd_pemilik_id: opdFinal,
        })
        .eq("id", id);
      if (error) throw new Error(error.message);
    } else {
      const { data: ins, error } = await supabaseAdmin
        .from("announcements")
        .insert({
          judul: data.judul,
          isi: data.isi,
          prioritas: data.prioritas,
          link: data.link ?? null,
          opd_pemilik_id: opdFinal,
          status: "draft",
          created_by: userId,
        })
        .select("id")
        .single();
      if (error) throw new Error(error.message);
      id = ins.id;
    }

    // Replace targets.
    await supabaseAdmin.from("announcement_targets").delete().eq("announcement_id", id!);
    if (data.targets.length > 0) {
      const { error } = await supabaseAdmin.from("announcement_targets").insert(
        data.targets.map((t) => ({
          announcement_id: id!,
          target_type: t.target_type,
          target_value: t.target_value,
        })),
      );
      if (error) throw new Error(error.message);
    }
    return { id: id! };
  });

export const publishAnnouncement = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => z.object({ id: z.string().uuid() }).parse(input))
  .handler(async ({ data, context }) => {
    const { userId } = context as { userId: string };
    const { data: row } = await supabaseAdmin
      .from("announcements")
      .select("id,judul,isi,link,prioritas,opd_pemilik_id,status")
      .eq("id", data.id)
      .maybeSingle();
    if (!row) throw new Error("Pengumuman tidak ditemukan");
    await assertCanManage(userId, row.opd_pemilik_id);

    // Resolve target users.
    const { data: targets } = await supabaseAdmin
      .from("announcement_targets")
      .select("target_type,target_value")
      .eq("announcement_id", data.id);
    const targetRows = ((targets ?? []) as Array<{ target_type: string; target_value: string | null }>).map(
      (t) => ({ target_type: t.target_type, target_value: t.target_value }),
    );
    const users = await resolveUsersFromTargetRows(supabaseAdmin, targetRows, row.opd_pemilik_id ?? null);

    // Set published.
    const { error: upErr } = await supabaseAdmin
      .from("announcements")
      .update({ status: "published", published_at: new Date().toISOString() })
      .eq("id", data.id);
    if (upErr) throw new Error(upErr.message);

    // Push notifications.
    if (users.length > 0) {
      const bodyPreview = (row.isi ?? "").slice(0, 240);
      await enqueueMany(
        users.map((u) => ({
          userId: u.user_id,
          tipe: "announcement.published",
          judul: `[Pengumuman] ${row.judul}`,
          body: bodyPreview || null,
          link: row.link || `/notifikasi`,
          meta: { announcement_id: data.id, prioritas: row.prioritas },
          dedupeKey: `announcement:${data.id}`,
        })),
      );
    }
    return { ok: true, recipients: users.length };
  });

export const deleteAnnouncement = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => z.object({ id: z.string().uuid() }).parse(input))
  .handler(async ({ data, context }) => {
    const { userId } = context as { userId: string };
    const { data: row } = await supabaseAdmin
      .from("announcements")
      .select("id,opd_pemilik_id")
      .eq("id", data.id)
      .maybeSingle();
    if (!row) return { ok: true };
    await assertCanManage(userId, row.opd_pemilik_id);
    const { error } = await supabaseAdmin.from("announcements").delete().eq("id", data.id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

export const previewRecipientCount = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) =>
    z
      .object({
        opd_pemilik_id: z.string().uuid().nullable().optional(),
        targets: z.array(TargetSchema).default([]),
      })
      .parse(input),
  )
  .handler(async ({ data }) => {
    const users = await resolveUsersFromTargetRows(
      supabaseAdmin,
      data.targets.map((t) => ({ target_type: t.target_type, target_value: t.target_value })),
      data.opd_pemilik_id ?? null,
    );
    return { count: users.length };
  });

// Daftar pengumuman terbit yang relevan untuk pengguna yang sedang login.
// Hanya membaca ringkasan pengumuman (bukan data pribadi pengguna lain).
export const listMyAnnouncements = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { userId } = context as { userId: string };
    const ctx = await getUserContext(supabaseAdmin, userId);
    const { data: rows, error } = await supabaseAdmin
      .from("announcements")
      .select("id,judul,isi,prioritas,link,published_at,opd_pemilik_id")
      .eq("status", "published")
      .order("published_at", { ascending: false })
      .limit(50);
    if (error) throw new Error(error.message);
    const list = rows ?? [];
    if (list.length === 0) return { rows: [] };

    const { data: targets } = await supabaseAdmin
      .from("announcement_targets")
      .select("announcement_id,target_type,target_value")
      .in(
        "announcement_id",
        list.map((r) => r.id),
      );
    const byId = new Map<string, Array<{ target_type: string; target_value: string | null }>>();
    for (const t of (targets ?? []) as Array<{
      announcement_id: string;
      target_type: string;
      target_value: string | null;
    }>) {
      const arr = byId.get(t.announcement_id) ?? [];
      arr.push({ target_type: t.target_type, target_value: t.target_value });
      byId.set(t.announcement_id, arr);
    }

    const visible = list.filter((row) => {
      const ts = byId.get(row.id) ?? [];
      if (ts.length === 0) return true; // tanpa target = pengumuman umum
      return ts.some((t) => {
        if (t.target_type === "role") return !!t.target_value && ctx.roleSet.has(t.target_value);
        if (t.target_type === "opd") return !!ctx.opdId && t.target_value === ctx.opdId;
        if (t.target_type === "individu") return t.target_value === userId;
        return false;
      });
    });
    return { rows: visible };
  });

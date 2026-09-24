// Notification producer + reader. Producer uses supabaseAdmin (RLS blocks
// regular user INSERT). Reader/mutator uses the authenticated client via
// middleware context (RLS-scoped to current user).
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";
import { supabaseAdmin } from "@/integrations/supabase/client.server";
import { log, newCorrelationId } from "./logger";
import { withIdempotency, idemKey } from "./http/idempotency";
import { checkRateLimit } from "@/integrations/supabase/rate-limit.server";
import { enqueueRetry } from "@/lib/queue/retry.server";

export type EnqueueArgs = {
  userId: string;
  tipe: string;
  judul: string;
  body?: string | null;
  link?: string | null;
  meta?: Record<string, unknown> | null;
  /** Dedup key. If provided and a recent (24h) notification with same key
   * exists for same user+tipe, skip insert (idempotent producer). */
  dedupeKey?: string | null;
};

export async function enqueueNotification(args: EnqueueArgs): Promise<void> {
  try {
    if (args.dedupeKey) {
      const { data: existing } = await supabaseAdmin
        .from("notifications")
        .select("id")
        .eq("user_id", args.userId)
        .eq("tipe", args.tipe)
        .contains("meta", { dedupe_key: args.dedupeKey } as never)
        .gte("created_at", new Date(Date.now() - 24 * 3600 * 1000).toISOString())
        .limit(1)
        .maybeSingle();
      if (existing) return;
    }
    const meta = {
      ...(args.meta ?? {}),
      ...(args.dedupeKey ? { dedupe_key: args.dedupeKey } : {}),
    };
    await supabaseAdmin.from("notifications").insert({
      user_id: args.userId,
      tipe: args.tipe,
      judul: args.judul,
      body: args.body ?? null,
      link: args.link ?? null,
      meta: meta as never,
    });
    // Fire-and-forget web push (jangan blok caller kalau gagal).
    try {
      const { sendWebPushToUser } = await import("@/lib/push/web-push.server");
      await sendWebPushToUser(args.userId, {
        title: args.judul,
        body: args.body ?? undefined,
        url: args.link ?? "/notifikasi",
        tag: args.dedupeKey ?? args.tipe,
      });
    } catch (e) {
      log.warn("push.send.notif.fail", {
        userId: args.userId,
        error: e instanceof Error ? e.message : String(e),
      });
    }
  } catch (e) {
    log.error("notification.enqueue.fail", {
      userId: args.userId,
      tipe: args.tipe,
      error: e instanceof Error ? e.message : String(e),
    });
    // F2.2 — schedule transient retry for background notification insert.
    try {
      await enqueueRetry({
        jobName: "notif.insert",
        payload: args as unknown as Record<string, unknown>,
        maxAttempts: 4,
        delaySec: 10,
      });
    } catch {
      /* never block caller */
    }
  }
}

export async function enqueueMany(items: EnqueueArgs[]): Promise<void> {
  if (items.length === 0) return;
  // Chunk to avoid oversized inserts (1000 cap).
  const CHUNK = 500;
  for (let i = 0; i < items.length; i += CHUNK) {
    const slice = items.slice(i, i + CHUNK);
    try {
      await supabaseAdmin.from("notifications").insert(
        slice.map((i) => ({
          user_id: i.userId,
          tipe: i.tipe,
          judul: i.judul,
          body: i.body ?? null,
          link: i.link ?? null,
          meta: (i.meta as never) ?? null,
        })),
      );
    } catch (e) {
      log.error("notification.enqueueMany.fail", {
        count: slice.length,
        error: e instanceof Error ? e.message : String(e),
      });
    }
  }
  // Fire-and-forget web push untuk seluruh recipient.
  try {
    const { sendWebPushToMany } = await import("@/lib/push/web-push.server");
    await sendWebPushToMany(
      items.map((i) => ({
        userId: i.userId,
        payload: {
          title: i.judul,
          body: i.body ?? undefined,
          url: i.link ?? "/notifikasi",
          tag: i.dedupeKey ?? i.tipe,
        },
      })),
    );
  } catch (e) {
    log.warn("push.send.many.fail", {
      count: items.length,
      error: e instanceof Error ? e.message : String(e),
    });
  }
}

// ===================== Recipient helpers =====================

/** Ambil semua user_id dengan role super_admin. */
export async function listSuperAdminIds(): Promise<string[]> {
  const { data } = await supabaseAdmin
    .from("user_roles")
    .select("user_id")
    .eq("role", "super_admin");
  return Array.from(
    new Set(((data ?? []) as Array<{ user_id: string }>).map((r) => r.user_id)),
  );
}

/** Ambil semua user_id admin_opd untuk OPD tertentu. */
export async function listOpdAdminIds(opdId: string | null | undefined): Promise<string[]> {
  if (!opdId) return [];
  const { data: adminRows } = await supabaseAdmin
    .from("user_roles")
    .select("user_id")
    .eq("role", "admin_opd");
  const adminIds = ((adminRows ?? []) as Array<{ user_id: string }>).map((r) => r.user_id);
  if (adminIds.length === 0) return [];
  const { data: profs } = await supabaseAdmin
    .from("profiles")
    .select("id")
    .eq("opd_id", opdId)
    .in("id", adminIds);
  return ((profs ?? []) as Array<{ id: string }>).map((p) => p.id);
}

/** Kirim notifikasi identik ke banyak user (dedupe user_id, skip empty). */
export async function notifyRecipients(
  userIds: Array<string | null | undefined>,
  base: Omit<EnqueueArgs, "userId">,
): Promise<void> {
  const unique = Array.from(
    new Set(userIds.filter((x): x is string => typeof x === "string" && x.length > 0)),
  );
  if (unique.length === 0) return;
  await enqueueMany(unique.map((id) => ({ ...base, userId: id })));
}

// ===================== Reader / Mutator (RLS-scoped) =====================

export const listMyNotifications = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) =>
    z
      .object({
        page: z.number().int().min(0).default(0),
        pageSize: z.number().int().min(1).max(50).default(20),
        onlyUnread: z.boolean().default(false),
        kategori: z
          .enum([
            "all",
            "assignment",
            "review",
            "approval",
            "rejection",
            "revision",
            "upload",
            "sharing",
            "system",
          ])
          .default("all"),
      })
      .parse(input ?? {}),
  )
  .handler(async ({ data, context }) => {
    const { userId } = context as { userId: string };
    const supabase = supabaseAdmin;
    let q = supabase
      .from("notifications")
      .select("id,tipe,judul,body,link,meta,dibaca,created_at", { count: "exact" })
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .range(data.page * data.pageSize, data.page * data.pageSize + data.pageSize - 1);
    if (data.onlyUnread) q = q.eq("dibaca", false);
    if (data.kategori !== "all") {
      const prefixMap: Record<string, string[]> = {
        assignment: ["form.assigned"],
        review: ["form.submitted"],
        approval: ["form.approved"],
        rejection: ["form.rejected"],
        revision: ["form.revision_required"],
        upload: ["upload."],
        sharing: ["share.", "document_access."],
        system: ["system."],
      };
      const prefixes = prefixMap[data.kategori] ?? [];
      if (prefixes.length) {
        const ors = prefixes.map((p) => `tipe.ilike.${p}%`).join(",");
        q = q.or(ors);
      }
    }
    const { data: rows, count, error } = await q;
    if (error) throw new Error(error.message);
    return { rows: rows ?? [], total: count ?? 0 };
  });

export const unreadCount = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { userId } = context as { userId: string };
    const supabase = supabaseAdmin;
    const { count, error } = await supabase
      .from("notifications")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .eq("dibaca", false);
    if (error) throw new Error(error.message);
    return { count: count ?? 0 };
  });

export const markRead = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) =>
    z.object({ ids: z.array(z.string().uuid()).min(1).max(100) }).parse(input),
  )
  .handler(async ({ data, context }) => {
    const { userId } = context as { userId: string };
    const supabase = supabaseAdmin;
    const { error } = await supabase
      .from("notifications")
      .update({ dibaca: true })
      .in("id", data.ids)
      .eq("user_id", userId)
      .eq("dibaca", false);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

export const markAllRead = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { userId } = context as { userId: string };
    const supabase = supabaseAdmin;
    const correlationId = newCorrelationId();
    const rl = await checkRateLimit(userId, "notif.markall", 5, 10);
    if (!rl.ok) {
      log.warn("notif.markAllRead.rate_limited", { userId, correlationId });
      throw new Error("Terlalu banyak permintaan, coba lagi sebentar");
    }
    const key = idemKey("notif:markall", userId);
    return withIdempotency(key, 10_000, async () => {
      const { error } = await supabase
        .from("notifications")
        .update({ dibaca: true })
        .eq("user_id", userId)
        .eq("dibaca", false);
      if (error) {
        log.error("notif.markAllRead.fail", { userId, correlationId, error: error.message });
        throw new Error(error.message);
      }
      log.info("notif.markAllRead.ok", { userId, correlationId });
      return { ok: true };
    });
  });

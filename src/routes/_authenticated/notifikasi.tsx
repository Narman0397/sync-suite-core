// Halaman penuh daftar notifikasi pengguna (target tautan default notifikasi).
import { useCallback, useEffect, useState } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { CheckCheck } from "lucide-react";
import { PageShell } from "@/components/site/PageShell";
import { listMyNotifications, markAllRead, markRead } from "@/lib/notifications.functions";

type Notif = {
  id: string;
  tipe: string;
  judul: string;
  body: string | null;
  link: string | null;
  dibaca: boolean;
  created_at: string;
};

export const Route = createFileRoute("/_authenticated/notifikasi")({
  head: () => ({
    meta: [
      { title: "Notifikasi Saya — Portal Buton Selatan" },
      { name: "description", content: "Daftar notifikasi dan pengumuman yang ditujukan kepada Anda." },
      { name: "robots", content: "noindex" },
      { property: "og:title", content: "Notifikasi Saya" },
      { property: "og:description", content: "Daftar notifikasi dan pengumuman untuk akun Anda." },
    ],
  }),
  component: NotifikasiPage,
});

const PAGE_SIZE = 20;

function NotifikasiPage() {
  const [rows, setRows] = useState<Notif[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async (target: number, reset: boolean) => {
    setLoading(true);
    setError(null);
    try {
      const r = (await listMyNotifications({
        data: { page: target, pageSize: PAGE_SIZE },
      })) as unknown as { rows: Notif[]; total: number };
      setTotal(r.total ?? 0);
      setRows((prev) => (reset ? (r.rows ?? []) : [...prev, ...(r.rows ?? [])]));
      setPage(target);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Gagal memuat notifikasi");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load(0, true);
  }, [load]);

  async function handleMarkAll() {
    setRows((rs) => rs.map((r) => ({ ...r, dibaca: true })));
    try {
      await markAllRead();
    } catch {
      /* abaikan */
    }
  }

  async function open(n: Notif) {
    if (n.dibaca) return;
    setRows((rs) => rs.map((r) => (r.id === n.id ? { ...r, dibaca: true } : r)));
    try {
      await markRead({ data: { ids: [n.id] } });
    } catch {
      /* abaikan */
    }
  }

  return (
    <PageShell>
      <div className="container-page py-10">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="font-display text-2xl font-bold">Notifikasi Saya</h1>
            <p className="text-sm text-muted-foreground">
              Pemberitahuan tugas, pengumuman, dan perubahan status permohonan.
            </p>
          </div>
          <button
            type="button"
            onClick={handleMarkAll}
            className="inline-flex h-9 items-center gap-1 rounded-md border border-border px-3 text-xs font-medium hover:bg-muted"
          >
            <CheckCheck className="h-3.5 w-3.5" /> Tandai semua dibaca
          </button>
        </div>

        <div className="mt-6 overflow-hidden rounded-xl border border-border bg-card">
          {loading && rows.length === 0 && (
            <div className="px-4 py-10 text-center text-sm text-muted-foreground">Memuat…</div>
          )}
          {error && (
            <div className="px-4 py-10 text-center text-sm text-destructive">{error}</div>
          )}
          {!loading && !error && rows.length === 0 && (
            <div className="px-4 py-14 text-center text-sm text-muted-foreground">
              Belum ada notifikasi.
            </div>
          )}
          {rows.map((n) => {
            const body = (
              <div
                className={`flex flex-col gap-1 border-b border-border/60 px-4 py-3 text-sm transition hover:bg-muted ${
                  n.dibaca ? "opacity-70" : "bg-primary/[0.03]"
                }`}
              >
                <span className="font-medium leading-tight">{n.judul}</span>
                {n.body && <span className="text-xs text-muted-foreground">{n.body}</span>}
                <span className="text-[10px] uppercase tracking-wide text-muted-foreground">
                  {new Date(n.created_at).toLocaleString("id-ID")}
                </span>
              </div>
            );
            return n.link ? (
              <Link key={n.id} to={n.link} onClick={() => open(n)}>
                {body}
              </Link>
            ) : (
              <button
                key={n.id}
                type="button"
                onClick={() => open(n)}
                className="block w-full text-left"
              >
                {body}
              </button>
            );
          })}
          {rows.length < total && (
            <button
              type="button"
              disabled={loading}
              onClick={() => load(page + 1, false)}
              className="block w-full px-4 py-3 text-center text-xs text-muted-foreground hover:bg-muted disabled:opacity-50"
            >
              {loading ? "Memuat…" : "Muat lebih banyak"}
            </button>
          )}
        </div>
      </div>
    </PageShell>
  );
}

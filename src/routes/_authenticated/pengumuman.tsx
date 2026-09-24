// Halaman pengumuman untuk pengguna (target tautan notifikasi pengumuman).
import { useEffect, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { Megaphone } from "lucide-react";
import { PageShell, PageHero } from "@/components/site/PageShell";
import { listMyAnnouncements } from "@/lib/announcements.functions";

type Row = {
  id: string;
  judul: string;
  isi: string | null;
  prioritas: string;
  link: string | null;
  published_at: string | null;
};

export const Route = createFileRoute("/_authenticated/pengumuman")({
  head: () => ({
    meta: [
      { title: "Pengumuman — Portal Buton Selatan" },
      {
        name: "description",
        content: "Pengumuman resmi yang ditujukan untuk akun Anda di Portal Buton Selatan.",
      },
      { name: "robots", content: "noindex" },
      { property: "og:title", content: "Pengumuman" },
      { property: "og:description", content: "Pengumuman resmi untuk akun Anda." },
    ],
  }),
  component: PengumumanPage,
});

const TONE: Record<string, string> = {
  info: "bg-primary-soft text-primary",
  penting: "bg-gold/20 text-gold-foreground",
  urgent: "bg-destructive/15 text-destructive",
};

function PengumumanPage() {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;
    listMyAnnouncements()
      .then((r) => {
        if (alive) setRows((r as unknown as { rows: Row[] }).rows ?? []);
      })
      .catch((e: unknown) => {
        if (alive) setError(e instanceof Error ? e.message : "Gagal memuat pengumuman");
      })
      .finally(() => {
        if (alive) setLoading(false);
      });
    return () => {
      alive = false;
    };
  }, []);

  return (
    <PageShell>
      <PageHero
        eyebrow="Informasi Internal"
        title="Pengumuman untuk Anda."
        description="Pengumuman resmi yang diterbitkan Super Admin maupun OPD sesuai penerima yang ditetapkan."
      />
      <section className="container-page py-12">
        {loading && <div className="text-sm text-muted-foreground">Memuat…</div>}
        {error && <div className="text-sm text-destructive">{error}</div>}
        {!loading && !error && rows.length === 0 && (
          <div className="rounded-2xl border border-dashed border-border bg-card p-12 text-center">
            <Megaphone className="mx-auto h-8 w-8 text-muted-foreground" />
            <h2 className="mt-3 font-display text-lg font-bold">Belum ada pengumuman</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              Pengumuman akan tampil di sini setelah diterbitkan untuk akun Anda.
            </p>
          </div>
        )}
        <div className="grid gap-4">
          {rows.map((r) => (
            <article key={r.id} className="rounded-xl border border-border bg-card p-5 shadow-soft">
              <div className="flex flex-wrap items-center gap-2 text-xs">
                <span
                  className={`rounded-full px-2.5 py-1 font-medium uppercase ${TONE[r.prioritas] ?? TONE.info}`}
                >
                  {r.prioritas}
                </span>
                <span className="text-muted-foreground">
                  {r.published_at ? new Date(r.published_at).toLocaleString("id-ID") : "—"}
                </span>
              </div>
              <h2 className="mt-3 text-lg font-semibold leading-snug">{r.judul}</h2>
              {r.isi && (
                <p className="mt-2 whitespace-pre-line text-sm text-muted-foreground">{r.isi}</p>
              )}
            </article>
          ))}
        </div>
      </section>
    </PageShell>
  );
}

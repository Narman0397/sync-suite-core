// Portal Data Terbuka — detail per slug.
import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { PageHero, PageShell } from "@/components/site/PageShell";
import { getPublicFormBySlug } from "@/lib/forms-extras.functions";

export const Route = createFileRoute("/data-terbuka/$slug")({
  head: ({ params }) => ({
    meta: [
      { title: `Data: ${params.slug} — Portal Pemerintah` },
      {
        name: "description",
        content: "Detail dataset publik (skema kolom dan ringkasan agregat).",
      },
      { property: "og:title", content: `Data ${params.slug} — Portal Buton Selatan` },
      { property: "og:description", content: "Detail skema dan ringkasan dataset publik terverifikasi." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: DetailPage,
});

type Result = {
  form: {
    id: string;
    judul: string;
    deskripsi: string | null;
    published_at: string | null;
    opd: { nama: string; singkatan: string | null } | null;
  } | null;
  fields: Array<{ kode: string; label: string; tipe: string; urutan: number }>;
  stats: { total: number };
};

function DetailPage() {
  const { slug } = Route.useParams();
  const [data, setData] = useState<Result | null>(null);
  const [busy, setBusy] = useState(true);

  useEffect(() => {
    let m = true;
    getPublicFormBySlug({ data: { slug } })
      .then((r) => {
        if (m) setData(r as unknown as Result);
      })
      .catch(() => void 0)
      .finally(() => {
        if (m) setBusy(false);
      });
    return () => {
      m = false;
    };
  }, [slug]);

  return (
    <PageShell>
      <PageHero eyebrow="Data Terbuka" title={data?.form?.judul ?? "Detail dataset publik"} description="Skema dan ringkasan data yang dipublikasikan pemerintah daerah." />
      <main className="container-page max-w-3xl py-12">
        {busy && <p className="text-sm text-muted-foreground">Memuat…</p>}
        {!busy && !data?.form && (
          <p className="text-sm text-muted-foreground">
            Dataset tidak ditemukan atau belum dipublikasikan.
          </p>
        )}
        {data?.form && (
          <article className="public-panel border-t-4 border-t-primary p-6 md:p-8">
            <div className="text-xs text-muted-foreground">
              {data.form.opd?.nama ?? "Pemerintah Daerah"}
            </div>
            {data.form.deskripsi && (
              <p className="mt-2 text-sm text-muted-foreground">{data.form.deskripsi}</p>
            )}
            <div className="mt-4 inline-flex items-center gap-2 rounded-md bg-muted/40 px-3 py-1.5 text-xs">
              Total submisi terverifikasi: <strong>{data.stats.total}</strong>
            </div>

            <h2 className="mt-8 mb-2 font-display text-lg font-semibold">Skema Kolom</h2>
            <div className="overflow-x-auto rounded-xl border border-border bg-card">
              <table className="min-w-full text-sm">
                <thead className="bg-muted/40 text-left text-xs uppercase text-muted-foreground">
                  <tr>
                    <th className="px-3 py-2">Kode</th>
                    <th className="px-3 py-2">Label</th>
                    <th className="px-3 py-2">Tipe</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {data.fields.map((f) => (
                    <tr key={f.kode}>
                      <td className="px-3 py-2 font-mono text-xs">{f.kode}</td>
                      <td className="px-3 py-2">{f.label}</td>
                      <td className="px-3 py-2 text-xs">{f.tipe}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <p className="mt-4 text-xs text-muted-foreground">
              Data individual tidak ditampilkan untuk melindungi privasi. Hubungi OPD pemilik untuk
              permintaan agregasi lebih lanjut.
            </p>
          </article>
        )}
      </main>
    </PageShell>
  );
}

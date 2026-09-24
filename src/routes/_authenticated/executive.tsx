// Dashboard Pimpinan Kabupaten — satu ringkasan eksekutif read-only untuk pimpinan daerah.
import { createFileRoute, Link } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { ExecutiveGuard } from "@/components/admin/ExecutiveGuard";
import { useAuthRoles } from "@/lib/auth-context";
import { supabase } from "@/integrations/supabase/client";
import { executiveOpdQueryOptions, executiveSummaryQueryOptions } from "@/lib/executive.queries";
import type { ExecutiveSummary } from "@/lib/executive.functions";
import type { SkorRow } from "@/lib/kinerja.functions";
import {
  AlertTriangle,
  Building2,
  Users,
  FileText,
  Package,
  MessageSquare,
  BarChart3,
  Database,
  Inbox,
  CheckCircle2,
  Clock,
  Gauge,
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/executive")({
  head: () => ({
    meta: [
      { title: "Dashboard Pimpinan Kabupaten" },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: () => (
    <ExecutiveGuard mode="executive">
      <Page />
    </ExecutiveGuard>
  ),
});

type Kab = ExecutiveSummary["kabupaten"];

function Page() {
  const { isBupati } = useAuthRoles();
  const summaryQ = useQuery(executiveSummaryQueryOptions());
  const opdQ = useQuery(executiveOpdQueryOptions());

  const bupatiQ = useQuery({
    queryKey: ["executive", "bupati-queue"],
    enabled: isBupati,
    staleTime: 60_000,
    refetchInterval: 60_000,
    queryFn: async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const sb: any = supabase;
      const [disp, appr] = await Promise.all([
        sb
          .from("submission_dispositions")
          .select("id", { count: "exact", head: true })
          .is("acted_at", null),
        sb.from("permohonan").select("id", { count: "exact", head: true }).eq("status", "diproses"),
      ]);
      if (disp.error) throw new Error(disp.error.message);
      if (appr.error) throw new Error(appr.error.message);
      return {
        disposisiAktif: (disp.count ?? 0) as number,
        approvalPending: (appr.count ?? 0) as number,
      };
    },
  });

  const kab = summaryQ.data?.kabupaten ?? null;
  const generatedAt = summaryQ.data?.generated_at ?? null;
  const skor = opdQ.data ?? [];

  return (
    <div className="min-h-screen bg-surface p-4 pb-16 md:p-8">
      <div className="mx-auto max-w-7xl space-y-8">
        <Header
          generatedAt={generatedAt}
          loading={summaryQ.isPending}
          error={summaryQ.isError}
          onRefresh={() => {
            void summaryQ.refetch();
            void opdQ.refetch();
          }}
        />

        <ExecutiveStatus q={summaryQ} kab={kab} />

        <Attention kab={kab} skor={skor} summaryQ={summaryQ} opdQ={opdQ} />

        <Section title="Pelayanan Publik" caption="Permohonan layanan lintas OPD">
          <MetricGrid
            state={stateOf(summaryQ, kab)}
            errorLabel="Data pelayanan publik gagal dimuat"
            items={[
              { label: "Total Permohonan", value: kab?.permohonan_total, icon: FileText },
              { label: "Bulan Ini", value: kab?.permohonan_bulan, icon: FileText },
              { label: "Selesai", value: kab?.permohonan_selesai, icon: CheckCircle2 },
              { label: "Backlog", value: diff(kab?.permohonan_total, kab?.permohonan_selesai), icon: Inbox },
              {
                label: "Overdue",
                value: kab?.permohonan_overdue,
                icon: AlertTriangle,
                tone: pos(kab?.permohonan_overdue) ? "destructive" : "default",
              },
              {
                label: "SLA Tepat Waktu",
                value: kab?.sla_on_time_pct,
                suffix: "%",
                icon: Gauge,
              },
            ]}
          />
        </Section>

        <Section
          title="Pengaduan Masyarakat"
          caption="Laporan warga melalui kanal LAPOR"
        >
          <MetricGrid
            state={stateOf(summaryQ, kab)}
            errorLabel="Data pengaduan gagal dimuat"
            items={[
              { label: "Total Pengaduan", value: kab?.laporan_total, icon: MessageSquare },
              { label: "Baru", value: kab?.laporan_baru, icon: Inbox },
              {
                label: "Pengaduan Aktif",
                value: kab?.laporan_open,
                icon: MessageSquare,
                tone: pos(kab?.laporan_open) ? "gold" : "default",
              },
              {
                label: "Selesai",
                value: kab?.laporan_selesai ?? diff(kab?.laporan_total, kab?.laporan_open),
                icon: CheckCircle2,
              },
            ]}
          />
          <p className="mt-3 text-xs text-muted-foreground">
            Hanya ringkasan jumlah per status. Identitas dan isi pengaduan tidak ditampilkan.
            Waktu respons: sumber data belum tersedia.
          </p>
        </Section>

        <Section title="Kinerja OPD" caption="Skor komposit SLA, penyelesaian, dan rating">
          <OpdTable q={opdQ} rows={skor} />
        </Section>

        <div className="grid gap-6 lg:grid-cols-2">
          <Section title="ASN & Kepegawaian" caption="Indikator kepegawaian tingkat kabupaten">
            <MetricGrid
              state={stateOf(summaryQ, kab)}
              errorLabel="Data kepegawaian gagal dimuat"
              items={[
                { label: "OPD", value: kab?.opd_count, icon: Building2 },
                { label: "ASN Terdaftar", value: kab?.asn_count, icon: Users },
                {
                  label: "Izin/Cuti Pending",
                  value: kab?.izin_pending,
                  icon: Clock,
                  tone: pos(kab?.izin_pending) ? "gold" : "default",
                },
                { label: "Responden IKM (30 hari)", value: kab?.ikm_responses_30d, icon: BarChart3 },
              ]}
              cols
            />
            <p className="mt-3 text-xs text-muted-foreground">
              {kab?.cuti_pending != null ? `Cuti pending: ${kab.cuti_pending}. ` : ""}
              {kab?.ikm_periode ? `Periode IKM: ${kab.ikm_periode}. ` : ""}
              Ringkasan jumlah saja — detail pengajuan dan jawaban IKM tidak ditampilkan.
            </p>
          </Section>

          <Section title="Aset Daerah" caption="Kondisi barang milik daerah">
            <MetricGrid
              state={stateOf(summaryQ, kab)}
              errorLabel="Data aset gagal dimuat"
              items={[
                { label: "Total Aset", value: kab?.aset_total, icon: Package },
                {
                  label: "Aset Rusak",
                  value: kab?.aset_rusak,
                  icon: AlertTriangle,
                  tone: pos(kab?.aset_rusak) ? "destructive" : "default",
                },
                { label: "Aset Layak", value: diff(kab?.aset_total, kab?.aset_rusak), icon: CheckCircle2 },
              ]}
              cols
            />
          </Section>
        </div>

        <Section title="Data & Dokumen" caption="Pengelolaan dataset dan submission">
          <MetricGrid
            state={stateOf(summaryQ, kab)}
            errorLabel="Data dataset gagal dimuat"
            items={[
              { label: "Template Aktif", value: kab?.dataset_template_active, icon: Database },
              { label: "Total Submission", value: kab?.dataset_submission_total, icon: Database },
              { label: "Submission Aktif", value: kab?.dataset_submission_active, icon: Inbox },
              {
                label: "Menunggu Review",
                value: kab?.dataset_review_pending,
                icon: Clock,
                tone: pos(kab?.dataset_review_pending) ? "gold" : "default",
              },
              {
                label: "Disetujui",
                value: kab?.dataset_submission_selesai,
                icon: CheckCircle2,
              },
            ]}
          />
        </Section>

        {isBupati && (
          <Section title="Antrean Bupati" caption="Butuh keputusan pimpinan">
            {bupatiQ.isError ? (
              <Notice tone="destructive">Data antrean gagal dimuat</Notice>
            ) : bupatiQ.isPending ? (
              <SkeletonGrid n={3} />
            ) : (
              <div className="grid gap-3 sm:grid-cols-3">
                <QueueLink
                  to="/admin/layanan"
                  label="Disposisi Aktif"
                  value={bupatiQ.data?.disposisiAktif ?? 0}
                  icon={Inbox}
                />
                <QueueLink
                  to="/admin/submission-review"
                  label="Persetujuan Dokumen"
                  value={bupatiQ.data?.approvalPending ?? 0}
                  icon={CheckCircle2}
                />
                <div className="rounded-xl border border-dashed border-border bg-card/60 p-4">
                  <div className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
                    Tanda Tangan Pending
                  </div>
                  <div className="mt-2 text-sm text-muted-foreground">
                    Sumber data belum tersedia
                  </div>
                </div>
              </div>
            )}
          </Section>
        )}
      </div>
    </div>
  );
}

/* ---------------- header & freshness ---------------- */

function Header({
  generatedAt,
  loading,
  error,
  onRefresh,
}: {
  generatedAt: string | null;
  loading: boolean;
  error: boolean;
  onRefresh: () => void;
}) {
  return (
    <header className="flex flex-col gap-3 border-b border-border pb-4 md:flex-row md:items-end md:justify-between">
      <div>
        <div className="text-xs font-medium uppercase tracking-widest text-muted-foreground">
          Pemerintah Kabupaten Buton Selatan
        </div>
        <h1 className="font-display text-2xl font-bold md:text-3xl">
          Dashboard Pimpinan Kabupaten
        </h1>
        <p className="text-sm text-muted-foreground">
          Kondisi pemerintahan dan pelayanan daerah — tampilan baca saja.
        </p>
      </div>
      <div className="flex items-center gap-3">
        <Freshness generatedAt={generatedAt} loading={loading} error={error} />
        <button
          type="button"
          onClick={onRefresh}
          className="h-9 rounded-md border border-border bg-card px-3 text-xs font-semibold text-foreground hover:bg-primary-soft hover:text-primary"
        >
          Perbarui
        </button>
      </div>
    </header>
  );
}

function Freshness({
  generatedAt,
  loading,
  error,
}: {
  generatedAt: string | null;
  loading: boolean;
  error: boolean;
}) {
  const [, tick] = useState(0);
  useEffect(() => {
    const id = setInterval(() => tick((n) => n + 1), 15_000);
    return () => clearInterval(id);
  }, []);

  let label = "Memuat data…";
  if (error) label = "Data gagal dimuat";
  else if (!loading && generatedAt) label = `Diperbarui ${relative(generatedAt)}`;
  else if (!loading && !generatedAt) label = "Waktu pembaruan tidak tersedia";

  return (
    <span className="inline-flex items-center gap-2 rounded-full border border-border bg-card px-3 py-1.5 text-xs text-muted-foreground">
      <span
        className={`h-2 w-2 rounded-full ${error ? "bg-destructive" : loading ? "bg-muted-foreground" : "bg-success"}`}
      />
      {label}
    </span>
  );
}

function relative(iso: string) {
  const diff = Date.now() - new Date(iso).getTime();
  if (!Number.isFinite(diff)) return "baru saja";
  const s = Math.max(0, Math.round(diff / 1000));
  if (s < 60) return `${s} detik lalu`;
  const m = Math.round(s / 60);
  if (m < 60) return `${m} menit lalu`;
  const h = Math.round(m / 60);
  if (h < 24) return `${h} jam lalu`;
  return new Date(iso).toLocaleDateString("id-ID", { day: "numeric", month: "short" });
}

/* ---------------- executive status ---------------- */

type QueryLike = { isPending: boolean; isError: boolean; error?: unknown };

type ViewState = "loading" | "error" | "empty" | "ready";

function stateOf(q: QueryLike, data: unknown): ViewState {
  if (q.isPending) return "loading";
  if (q.isError) return "error";
  if (data == null) return "empty";
  return "ready";
}

function ExecutiveStatus({ q, kab }: { q: QueryLike; kab: Kab | null }) {
  const state = stateOf(q, kab);
  return (
    <section>
      <h2 className="mb-3 font-display text-lg font-semibold">Kondisi Pemerintahan Hari Ini</h2>
      {state === "error" && <Notice tone="destructive">Data ringkasan pimpinan gagal dimuat</Notice>}
      {state === "empty" && <Notice tone="muted">Belum ada data ringkasan</Notice>}
      {state === "loading" && <SkeletonGrid n={4} tall />}
      {state === "ready" && kab && (
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          {kab.sla_on_time_pct == null ? (
            <Hero
              label="Layanan Aktif"
              value={kab.layanan_total == null ? null : fmt(kab.layanan_total)}
              hint={kab.opd_count == null ? "Layanan publik terdaftar" : `Tersebar di ${fmt(kab.opd_count)} OPD`}
            />
          ) : (
          <Hero
            label="SLA Tepat Waktu"
            value={`${Math.round(kab.sla_on_time_pct)}%`}
            hint="Permohonan selesai sesuai SLA"
            tone={kab.sla_on_time_pct >= 80 ? "success" : kab.sla_on_time_pct >= 60 ? "gold" : "destructive"}
          />
          )}
          <Hero
            label="Permohonan Bulan Ini"
            value={kab.permohonan_bulan == null ? null : fmt(kab.permohonan_bulan)}
            hint={
              kab.permohonan_selesai == null || kab.permohonan_total == null
                ? "Rincian penyelesaian belum tersedia"
                : `${fmt(kab.permohonan_selesai)} selesai dari ${fmt(kab.permohonan_total)} total`
            }
          />
          {kab.permohonan_overdue == null ? (
            <Hero
              label="Permohonan Diproses"
              value={kab.permohonan_diproses == null ? null : fmt(kab.permohonan_diproses)}
              hint="Sedang ditangani OPD"
            />
          ) : (
            <Hero
              label="Permohonan Overdue"
              value={fmt(kab.permohonan_overdue)}
              hint={kab.permohonan_overdue > 0 ? "Melebihi batas SLA" : "Tidak ada keterlambatan"}
              tone={kab.permohonan_overdue > 0 ? "destructive" : "success"}
            />
          )}
          {kab.laporan_open == null ? (
            <Hero
              label="OPD Terdaftar"
              value={kab.opd_count == null ? null : fmt(kab.opd_count)}
              hint={kab.user_total == null ? "Organisasi perangkat daerah" : `${fmt(kab.user_total)} pengguna terdaftar`}
            />
          ) : (
            <Hero
              label="Pengaduan Aktif"
              value={fmt(kab.laporan_open)}
              hint={kab.laporan_total == null ? "Pengaduan belum ditutup" : `${fmt(kab.laporan_total)} total pengaduan`}
              tone={pos(kab.laporan_open) ? "gold" : "success"}
            />
          )}
        </div>
      )}
    </section>
  );
}

function Hero({
  label,
  value,
  hint,
  tone = "default",
}: {
  label: string;
  value: string | null;
  hint: string;
  tone?: Tone;
}) {
  return (
    <div className="rounded-xl border border-border bg-card p-4 shadow-soft">
      <div className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
        {label}
      </div>
      {value == null ? (
        <UnavailableValue />
      ) : (
        <>
          <div className={`mt-2 font-display text-3xl font-bold leading-none ${toneText(tone)}`}>
            {value}
          </div>
          <div className="mt-2 text-xs text-muted-foreground">{hint}</div>
        </>
      )}

    </div>
  );
}

// Status netral: sumber data belum tersedia (bukan error, bukan nol).
function UnavailableValue({ note }: { note?: string }) {
  return (
    <div className="mt-2">
      <div className="font-display text-2xl font-bold leading-none text-muted-foreground/60">—</div>
      <div className="mt-1 text-xs text-muted-foreground">
        {note ?? "Data belum tersedia"}
      </div>
    </div>
  );
}


/* ---------------- attention ---------------- */

function Attention({
  kab,
  skor,
  summaryQ,
  opdQ,
}: {
  kab: Kab | null;
  skor: SkorRow[];
  summaryQ: QueryLike;
  opdQ: QueryLike;
}) {
  if (summaryQ.isPending || opdQ.isPending) return null;

  const items: { text: string; to?: string; tone: Tone }[] = [];
  if (summaryQ.isError) items.push({ text: "Data ringkasan pimpinan gagal dimuat", tone: "destructive" });
  if (opdQ.isError) items.push({ text: "Data kinerja OPD gagal dimuat", tone: "destructive" });
  if (kab) {
    if (pos(kab.permohonan_overdue))
      items.push({
        text: `${fmt(kab.permohonan_overdue!)} permohonan melewati batas SLA`,
        to: "/admin/permohonan",
        tone: "destructive",
      });
    if (pos(kab.laporan_open))
      items.push({
        text: `${fmt(kab.laporan_open!)} pengaduan masyarakat masih aktif`,
        to: "/admin/laporan",
        tone: "gold",
      });
    if (pos(kab.aset_rusak))
      items.push({
        text: `${fmt(kab.aset_rusak!)} aset dalam kondisi rusak`,
        to: "/admin/aset",
        tone: "gold",
      });
    if (pos(kab.dataset_review_pending))
      items.push({
        text: `${fmt(kab.dataset_review_pending!)} submission dataset menunggu review`,
        to: "/admin/dataset/review",
        tone: "gold",
      });
    if (pos(kab.izin_pending))
      items.push({
        text: `${fmt(kab.izin_pending!)} pengajuan izin/cuti menunggu persetujuan`,
        to: "/admin/izin",
        tone: "gold",
      });
  }
  const lowSla = skor.filter((r) => r.sla_pct != null && r.sla_pct < 70);
  for (const r of lowSla.slice(0, 3)) {
    items.push({
      text: `${r.opd_nama}: SLA ${Math.round(r.sla_pct ?? 0)}% (di bawah 70%)`,
      to: "/kinerja-opd",
      tone: "destructive",
    });
  }

  return (
    <section>
      <h2 className="mb-3 font-display text-lg font-semibold">Perlu Perhatian</h2>
      {items.length === 0 ? (
        <Notice tone="success">
          Tidak ada pengecualian terdeteksi dari data yang dimuat saat ini.
        </Notice>
      ) : (
        <ul className="divide-y divide-border overflow-hidden rounded-xl border border-border bg-card">
          {items.map((it, i) => (
            <li key={i} className="flex items-center gap-3 px-4 py-3 text-sm">
              <AlertTriangle className={`h-4 w-4 shrink-0 ${toneText(it.tone)}`} />
              <span className="flex-1">{it.text}</span>
              {it.to && (
                <Link
                  to={it.to}
                  className="shrink-0 text-xs font-semibold text-primary hover:underline"
                >
                  Tinjau
                </Link>
              )}
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

/* ---------------- OPD table ---------------- */

function OpdTable({ q, rows }: { q: QueryLike; rows: SkorRow[] }) {
  if (q.isPending) return <SkeletonGrid n={3} />;
  if (q.isError) return <Notice tone="destructive">Data kinerja OPD gagal dimuat</Notice>;
  if (rows.length === 0) return <Notice tone="muted">Belum ada data kinerja OPD</Notice>;

  const scored = rows.filter((r) => r.skor != null);
  const ranked = scored.length >= 5;
  const list = [...(ranked ? scored : rows)].sort((a, b) => (b.skor ?? 0) - (a.skor ?? 0));

  return (
    <div className="overflow-hidden rounded-xl border border-border bg-card">
      {!ranked && (
        <p className="border-b border-border px-4 py-2 text-xs text-muted-foreground">
          Data belum cukup untuk pemeringkatan — menampilkan seluruh OPD.
        </p>
      )}
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left text-xs uppercase tracking-wide text-muted-foreground">
              <th className="px-4 py-2 font-medium">OPD</th>
              <th className="px-3 py-2 text-right font-medium">SLA</th>
              <th className="px-3 py-2 text-right font-medium">Backlog</th>
              <th className="px-4 py-2 text-right font-medium">Skor</th>
            </tr>
          </thead>
          <tbody>
            {list.map((r) => {
              const backlog = Math.max(0, (r.total ?? 0) - (r.selesai ?? 0));
              const low = r.sla_pct != null && r.sla_pct < 70;
              return (
                <tr key={r.opd_id} className="border-b border-border/60 last:border-0">
                  <td className="px-4 py-2.5">
                    <div className="font-medium">{r.opd_singkatan || r.opd_nama}</div>
                    <div className="text-xs text-muted-foreground">{r.opd_nama}</div>
                  </td>
                  <td
                    className={`px-3 py-2.5 text-right tabular-nums ${low ? "text-destructive font-semibold" : ""}`}
                  >
                    {r.sla_pct == null ? "—" : `${Math.round(r.sla_pct)}%`}
                  </td>
                  <td className="px-3 py-2.5 text-right tabular-nums">{fmt(backlog)}</td>
                  <td className="px-4 py-2.5 text-right font-semibold tabular-nums">
                    {r.skor == null ? "—" : Math.round(r.skor)}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* ---------------- primitives ---------------- */

type Tone = "default" | "success" | "gold" | "destructive";

function toneText(tone: Tone) {
  if (tone === "success") return "text-success";
  if (tone === "gold") return "text-gold";
  if (tone === "destructive") return "text-destructive";
  return "text-foreground";
}

function diff(a: number | null | undefined, b: number | null | undefined) {
  if (a == null || b == null) return null;
  return Math.max(0, a - b);
}

function pos(n: number | null | undefined) {
  return n != null && n > 0;
}

function fmt(n: number) {
  return n.toLocaleString("id-ID");
}

function Section({
  title,
  caption,
  children,
}: {
  title: string;
  caption?: string;
  children: React.ReactNode;
}) {
  return (
    <section>
      <div className="mb-3">
        <h2 className="font-display text-lg font-semibold">{title}</h2>
        {caption && <p className="text-xs text-muted-foreground">{caption}</p>}
      </div>
      {children}
    </section>
  );
}

function MetricGrid({
  state,
  errorLabel,
  items,
  cols,
}: {
  state: ViewState;
  errorLabel: string;
  cols?: boolean;
  items: {
    label: string;
    value: number | null | undefined;
    icon: React.ComponentType<{ className?: string }>;
    tone?: Tone;
    suffix?: string;
  }[];
}) {
  if (state === "loading") return <SkeletonGrid n={items.length} />;
  if (state === "error") return <Notice tone="destructive">{errorLabel}</Notice>;
  if (state === "empty") return <Notice tone="muted">Belum ada data</Notice>;

  return (
    <div
      className={`grid grid-cols-2 gap-3 ${cols ? "lg:grid-cols-2" : "md:grid-cols-3 lg:grid-cols-6"}`}
    >
      {items.map((it) => (
        <div key={it.label} className="rounded-xl border border-border bg-card p-4 shadow-soft">
          <div className="flex items-start justify-between gap-2">
            <span className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
              {it.label}
            </span>
            <it.icon className={`h-4 w-4 shrink-0 ${toneText(it.tone ?? "default")}`} />
          </div>
          {it.value == null ? (
            <UnavailableValue />
          ) : (
            <div className={`mt-2 font-display text-2xl font-bold ${toneText(it.tone ?? "default")}`}>
              {`${fmt(Math.round(it.value))}${it.suffix ?? ""}`}
            </div>
          )}

        </div>
      ))}
    </div>
  );
}

function QueueLink({
  to,
  label,
  value,
  icon: Icon,
}: {
  to: string;
  label: string;
  value: number;
  icon: React.ComponentType<{ className?: string }>;
}) {
  return (
    <Link
      to={to}
      className="rounded-xl border border-border bg-card p-4 shadow-soft hover:bg-primary-soft hover:text-primary"
    >
      <div className="flex items-center justify-between">
        <span className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
          {label}
        </span>
        <Icon className="h-4 w-4 text-primary" />
      </div>
      <div className="mt-2 font-display text-2xl font-bold">{fmt(value)}</div>
    </Link>
  );
}

function Notice({ tone, children }: { tone: "muted" | "success" | "destructive"; children: React.ReactNode }) {
  const cls =
    tone === "destructive"
      ? "border-destructive/30 bg-destructive/10 text-destructive"
      : tone === "success"
        ? "border-success/30 bg-success/10 text-success"
        : "border-border bg-card text-muted-foreground";
  return <div className={`rounded-xl border p-4 text-sm ${cls}`}>{children}</div>;
}

function SkeletonGrid({ n, tall }: { n: number; tall?: boolean }) {
  return (
    <div className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-4">
      {Array.from({ length: n }).map((_, i) => (
        <div
          key={i}
          className={`animate-pulse rounded-xl border border-border bg-card ${tall ? "h-28" : "h-24"}`}
        />
      ))}
    </div>
  );
}

// Zona C — 5 Ekosistem Portal sebagai kartu padat-data.
import { Link } from "@tanstack/react-router";
import {
  Area,
  AreaChart,
  ResponsiveContainer,
} from "recharts";
import {
  ArrowUpRight,
  Boxes,
  Building2,
  Database,
  Inbox,
  Users,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { DashboardSectionHeader } from "./DashboardSectionHeader";

export type EcoMetric = { label: string; value: string | number; tone?: "ok" | "warn" | "crit" };
export type EcoShortcut = { label: string; to: string };
export type EcoSpark = { value: number };

export type EcosystemCardProps = {
  id: string;
  title: string;
  subtitle: string;
  icon: LucideIcon;
  metrics: EcoMetric[];
  shortcuts: EcoShortcut[];
  spark?: EcoSpark[];
  accent: "primary" | "accent" | "gold" | "success" | "destructive";
  primaryTo: string;
};

// Palet GovTech: netral (surface + foreground), aksen resmi hanya untuk ekosistem utama.
const accentMap = {
  primary: {
    badge: "bg-primary/10 text-primary",
    bar: "from-primary/20 to-primary/0",
    stroke: "oklch(0.55 0.16 258)",
  },
  accent: {
    badge: "bg-surface text-muted-foreground",
    bar: "from-border to-transparent",
    stroke: "oklch(0.55 0.16 258)",
  },
  gold: {
    badge: "bg-surface text-muted-foreground",
    bar: "from-border to-transparent",
    stroke: "oklch(0.55 0.16 258)",
  },
  success: {
    badge: "bg-surface text-muted-foreground",
    bar: "from-border to-transparent",
    stroke: "oklch(0.55 0.16 258)",
  },
  destructive: {
    badge: "bg-surface text-muted-foreground",
    bar: "from-border to-transparent",
    stroke: "oklch(0.55 0.16 258)",
  },
} as const;

export function EcosystemCard(p: EcosystemCardProps) {
  const a = accentMap[p.accent];
  const [primaryMetric, ...supportingMetrics] = p.metrics;
  return (
    <article className="group flex h-full min-w-0 flex-col overflow-hidden rounded-lg border border-border bg-card shadow-soft transition hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-elevated">
      <header className="grid grid-cols-[auto_minmax(0,1fr)_auto] items-start gap-3 p-3.5 sm:p-4">
        <span className={`grid h-10 w-10 shrink-0 place-items-center rounded-lg ${a.badge}`}>
          <p.icon className="h-5 w-5" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-xs font-semibold uppercase text-muted-foreground">Ekosistem {p.id === "layanan" ? "01" : p.id === "kinerja" ? "02" : p.id === "data" ? "03" : p.id === "asn" ? "04" : "05"}</p>
          <h3 className="mt-0.5 font-display text-base font-bold leading-tight text-foreground">{p.title}</h3>
          <p className="mt-1 text-xs leading-relaxed text-muted-foreground">{p.subtitle}</p>
        </div>
        <Link
          to={p.primaryTo}
          className="inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-md border border-border bg-background text-foreground hover:border-primary hover:text-primary"
          aria-label={`Buka ${p.title}`}
        >
          <ArrowUpRight className="h-3.5 w-3.5" />
        </Link>
      </header>

      {primaryMetric && (
        <div className="border-y border-border bg-surface/35 px-4 py-4">
          <div className={`font-display text-3xl font-bold leading-none ${metricTone(primaryMetric.tone)}`}>{primaryMetric.value}</div>
          <div className="mt-1.5 text-xs font-medium text-muted-foreground">{primaryMetric.label}</div>
        </div>
      )}

      {supportingMetrics.length > 0 && (
        <div
          className={`grid divide-x divide-border border-b border-border ${
            supportingMetrics.length === 2 ? "grid-cols-2" : "grid-cols-3"
          }`}
        >
          {supportingMetrics.map((m) => (
            <div
              key={m.label}
              className="min-w-0 bg-card px-2.5 py-3"
            >
              <div
                className={`min-h-8 break-words font-display text-sm font-bold leading-tight ${metricTone(m.tone)}`}
              >
                {m.value}
              </div>
              <div className="mt-1 line-clamp-2 min-h-7 text-[10px] font-medium leading-snug text-muted-foreground">{m.label}</div>
            </div>
          ))}
        </div>
      )}

      {p.spark && p.spark.length > 0 && (
        <div className="mt-2 h-9 w-full px-1" aria-label="Tren permohonan">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={p.spark} margin={{ top: 2, right: 2, bottom: 0, left: 2 }}>
              <defs>
                <linearGradient id={`sp-${p.id}`} x1="0" x2="0" y1="0" y2="1">
                  <stop offset="0%" stopColor={a.stroke} stopOpacity={0.4} />
                  <stop offset="100%" stopColor={a.stroke} stopOpacity={0} />
                </linearGradient>
              </defs>
              <Area
                type="monotone"
                dataKey="value"
                stroke={a.stroke}
                strokeWidth={1.5}
                fill={`url(#sp-${p.id})`}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      )}

      <footer className="mt-auto min-w-0 border-t border-border/70 p-3">
        <div className="flex gap-1.5 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          {p.shortcuts.map((s) => (
            <Link
              key={s.to + s.label}
              to={s.to}
              className="shrink-0 whitespace-nowrap rounded-md border border-border bg-background px-2.5 py-1.5 text-xs font-medium text-muted-foreground hover:border-primary/40 hover:text-primary"
            >
              {s.label}
            </Link>
          ))}
        </div>
      </footer>
    </article>
  );
}

function metricTone(tone: EcoMetric["tone"]) {
  return tone === "crit"
    ? "text-destructive"
    : tone === "warn"
      ? "text-gold-foreground"
      : tone === "ok"
        ? "text-success"
        : "text-foreground";
}

export type EcosystemData = {
  layananSpark: EcoSpark[];
  layanan: { total: number; today: number; slaOnTime: number | null; rating: number | null };
  kinerjaOpd: { opdAktif: number; pejabat: number; backlogTopName: string | null; backlogTopCount: number };
  data: { datasetAktif: number; submission: number; review: number };
  asn: { totalAsn: number; hadirHariIni: number | null; izinPending: number };
  aset: { totalAset: number; opnameAktif: number; warrantyExp: number | null };
};

export function EcosystemGrid(d: EcosystemData) {
  const cards: EcosystemCardProps[] = [
    {
      id: "layanan",
      title: "Pelayanan Publik",
      subtitle: "Permohonan warga, layanan OPD, pengaduan & rating.",
      icon: Inbox,
      accent: "primary",
      primaryTo: "/admin",
      spark: d.layananSpark,
      metrics: [
        { label: "Total", value: d.layanan.total },
        { label: "Hari Ini", value: d.layanan.today },
        {
          label: "SLA On-time",
          value: d.layanan.slaOnTime != null ? `${d.layanan.slaOnTime}%` : "—",
          tone:
            d.layanan.slaOnTime == null
              ? undefined
              : d.layanan.slaOnTime >= 80
                ? "ok"
                : d.layanan.slaOnTime >= 50
                  ? "warn"
                  : "crit",
        },
        {
          label: "Rating",
          value: d.layanan.rating != null ? d.layanan.rating.toFixed(1) : "—",
        },
      ],
      shortcuts: [
        { label: "Permohonan", to: "/admin" },
        { label: "Layanan", to: "/admin/layanan" },
        { label: "Pengaduan", to: "/admin/laporan" },
        { label: "Rating", to: "/admin/rating" },
      ],
    },
    {
      id: "kinerja",
      title: "Kinerja OPD",
      subtitle: "Pantau performa OPD, pejabat & evaluasi layanan.",
      icon: Building2,
      accent: "gold",
      primaryTo: "/kinerja-opd",
      metrics: [
        { label: "OPD Aktif", value: d.kinerjaOpd.opdAktif },
        { label: "Pejabat", value: d.kinerjaOpd.pejabat },
        {
          label: "Top Backlog",
          value: d.kinerjaOpd.backlogTopName ?? "—",
        },
        {
          label: "Antri",
          value: d.kinerjaOpd.backlogTopCount,
          tone: d.kinerjaOpd.backlogTopCount > 20 ? "warn" : undefined,
        },
      ],
      shortcuts: [
        { label: "Kinerja OPD", to: "/kinerja-opd" },
        { label: "Daftar OPD", to: "/admin/opd" },
        { label: "Pejabat", to: "/admin/pejabat" },
      ],
    },
    {
      id: "data",
      title: "Berbagi Data",
      subtitle: "Dataset terbuka, pengisian template & review.",
      icon: Database,
      accent: "accent",
      primaryTo: "/admin/dataset",
      metrics: [
        { label: "Template Aktif", value: d.data.datasetAktif },
        { label: "Pengisian", value: d.data.submission },
        {
          label: "Menunggu Review",
          value: d.data.review,
          tone: d.data.review > 0 ? "warn" : undefined,
        },
      ],
      shortcuts: [
        { label: "Dataset", to: "/admin/dataset" },
        { label: "Review", to: "/admin/dataset/review" },
        { label: "Data Terbuka", to: "/data-terbuka" },
      ],
    },
    {
      id: "asn",
      title: "Manajemen ASN",
      subtitle: "Data pegawai, kehadiran, izin/cuti & kepatuhan.",
      icon: Users,
      accent: "success",
      primaryTo: "/admin/asn",
      metrics: [
        { label: "Total ASN", value: d.asn.totalAsn },
        {
          label: "Hadir Hari Ini",
          value: d.asn.hadirHariIni != null ? d.asn.hadirHariIni : "—",
        },
        {
          label: "Izin Pending",
          value: d.asn.izinPending,
          tone: d.asn.izinPending > 0 ? "warn" : undefined,
        },
      ],
      shortcuts: [
        { label: "Data ASN", to: "/admin/asn" },
        { label: "Kepatuhan", to: "/admin/asn-kepatuhan" },
        { label: "Izin/Cuti", to: "/admin/izin" },
      ],
    },
    {
      id: "aset",
      title: "Manajemen Aset",
      subtitle: "Aset pemda, KIB, opname & pemeliharaan.",
      icon: Boxes,
      accent: "destructive",
      primaryTo: "/admin/aset",
      metrics: [
        { label: "Total Aset", value: d.aset.totalAset },
      ],
      shortcuts: [
        { label: "Data Aset", to: "/admin/aset" },
        { label: "KIB", to: "/admin/aset/kib" },
        { label: "Opname", to: "/admin/aset/opname" },
      ],
    },
  ];

  return (
    <section aria-labelledby="eco-title" className="mb-6">
      <DashboardSectionHeader
        eyebrow="Cakupan layanan"
        title="5 Ekosistem Pemerintahan"
        description="Ringkasan lintas layanan publik, kinerja, data, ASN, dan aset daerah."
      />
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-6 2xl:grid-cols-5">
        {cards.map((c, index) => (
          <div
            key={c.id}
            className={`min-w-0 ${
              index === 0
                ? "xl:col-span-2 2xl:col-span-1"
                : index < 3
                  ? "xl:col-span-2 2xl:col-span-1"
                  : "xl:col-span-3 2xl:col-span-1"
            }`}
          >
            <EcosystemCard {...c} />
          </div>
        ))}
      </div>
    </section>
  );
}

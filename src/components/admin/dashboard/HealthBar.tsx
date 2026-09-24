// Panel kesehatan sistem ringkas: 1 skor besar + 6 mikro-stat grid.
// Tidak lagi scroll horizontal. Semua label Bahasa Indonesia ramah-pengguna.
import { Link } from "@tanstack/react-router";
import {
  Activity,
  AlertTriangle,
  Bell,
  CheckCircle2,
  HardDrive,
  ListChecks,
  ShieldAlert,
  XCircle,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { DashboardSectionHeader } from "./DashboardSectionHeader";

type Tone = "ok" | "warn" | "crit" | "info";

interface Stat {
  label: string;
  value: string | number;
  tone: Tone;
  icon: LucideIcon;
  to: string;
  hint: string;
}

const toneText: Record<Tone, string> = {
  ok: "text-success",
  warn: "text-gold",
  crit: "text-destructive",
  info: "text-foreground",
};
const toneBg: Record<Tone, string> = {
  ok: "bg-success/10",
  warn: "bg-gold/15",
  crit: "bg-destructive/10",
  info: "bg-surface",
};

export function HealthBar({
  systemTone,
  systemScore,
  jobsPending,
  jobsFailed,
  jobsRunning,
  alertsCount,
  backupAgeHours,
  lastActivity,
}: {
  systemTone: Tone;
  systemScore: number | null;
  jobsPending: number;
  jobsFailed: number;
  jobsRunning: number;
  alertsCount: number;
  backupAgeHours: number | null;
  lastActivity: string | null;
}) {
  const scoreLabel =
    systemScore != null ? `${systemScore}` : systemTone === "ok" ? "OK" : "—";
  const scoreCaption =
    systemTone === "ok"
      ? "Sistem sehat"
      : systemTone === "warn"
        ? "Perlu perhatian"
        : systemTone === "crit"
          ? "Perlu tindakan"
          : "Menghitung…";
  const ScoreIcon =
    systemTone === "ok"
      ? CheckCircle2
      : systemTone === "crit"
        ? XCircle
        : ShieldAlert;
  const safeScore = Math.max(0, Math.min(100, systemScore ?? 0));

  const stats: Stat[] = [
    {
      label: "Peringatan",
      value: alertsCount,
      tone: alertsCount > 0 ? "crit" : "ok",
      icon: Bell,
      to: "/admin/monitoring/health",
      hint: "Notifikasi belum tertangani",
    },
    {
      label: "Pekerjaan Antri",
      value: jobsPending,
      tone: jobsPending > 50 ? "warn" : "info",
      icon: ListChecks,
      to: "/admin/monitoring/reliability",
      hint: `${jobsRunning} sedang berjalan`,
    },
    {
      label: "Pekerjaan Gagal",
      value: jobsFailed,
      tone: jobsFailed > 0 ? "crit" : "ok",
      icon: AlertTriangle,
      to: "/admin/monitoring/reliability",
      hint: "Gagal + macet (dead-letter)",
    },
    {
      label: "Cadangan Data",
      value: backupAgeHours != null ? `${backupAgeHours}j` : "—",
      tone:
        backupAgeHours == null
          ? "info"
          : backupAgeHours > 48
            ? "crit"
            : backupAgeHours > 26
              ? "warn"
              : "ok",
      icon: HardDrive,
      to: "/admin/monitoring/health",
      hint: "Sejak cadangan terakhir",
    },
    {
      label: "Aktivitas",
      value: lastActivity ? relTime(lastActivity) : "—",
      tone: "info",
      icon: Activity,
      to: "/admin/audit",
      hint: "Log audit terbaru",
    },
  ];

  return (
    <section aria-labelledby="health-title" className="mb-7">
      <DashboardSectionHeader
        eyebrow="Status operasional"
        title="Kondisi Sistem"
        description="Indikator turunan dari job gagal, tugas lewat tenggat, dan usia cadangan data."
      />
      <div className="grid overflow-hidden rounded-lg border border-border bg-card shadow-soft lg:grid-cols-[minmax(300px,0.9fr)_1.6fr]">
      <Link
        to="/admin/monitoring/health"
        aria-label={`Skor kesehatan sistem ${scoreLabel}, ${scoreCaption}`}
        className={`group grid min-h-48 grid-cols-[auto_minmax(0,1fr)] items-center gap-5 border-b border-border px-5 py-6 hover:bg-surface sm:px-7 lg:border-b-0 lg:border-r ${toneBg[systemTone]}`}
      >
        <span className={`relative grid h-28 w-28 shrink-0 place-items-center ${toneText[systemTone]}`}>
          <svg viewBox="0 0 120 120" className="absolute inset-0 h-full w-full -rotate-90" aria-hidden="true">
            <circle cx="60" cy="60" r="51" fill="none" stroke="currentColor" strokeOpacity="0.12" strokeWidth="9" />
            <circle
              cx="60"
              cy="60"
              r="51"
              fill="none"
              stroke="currentColor"
              strokeWidth="9"
              strokeLinecap="round"
              pathLength="100"
              strokeDasharray={`${safeScore} 100`}
            />
          </svg>
          <span className="relative text-center">
            <span className="block font-display text-3xl font-bold leading-none">{scoreLabel}</span>
            <span className="mt-1 block text-[10px] font-semibold text-muted-foreground">/ 100</span>
          </span>
        </span>
        <div className="min-w-0">
          <div className={`mb-2 inline-flex items-center gap-1.5 rounded-full bg-background/80 px-2.5 py-1 text-[10px] font-bold uppercase ${toneText[systemTone]}`}>
            <ScoreIcon className="h-3.5 w-3.5" />
            {systemTone === "ok" ? "Sehat" : systemTone === "warn" ? "Perhatian" : systemTone === "crit" ? "Kritis" : "Memuat"}
          </div>
          <div id="health-title" className={`font-display text-xl font-bold ${toneText[systemTone]}`}>{scoreCaption}</div>
          <p className="mt-1 max-w-52 text-xs leading-relaxed text-muted-foreground">
            {systemTone === "ok" ? "Tidak ada gangguan utama yang terdeteksi." : "Tinjau indikator yang memerlukan perhatian."}
          </p>
        </div>
      </Link>

      <ul className="grid grid-cols-2 divide-x divide-y divide-border sm:grid-cols-3 lg:grid-cols-5 lg:divide-y-0">
        {stats.map((s) => (
          <li key={s.label}>
            <Link
              to={s.to}
              title={s.hint}
              aria-label={`${s.label}: ${s.value}. ${s.hint}`}
              className="group flex min-h-24 flex-col items-start justify-center gap-2 bg-card px-3 py-3 hover:bg-surface"
            >
              <span
                className={`grid h-8 w-8 shrink-0 place-items-center rounded-md ${toneBg[s.tone]} ${toneText[s.tone]}`}
              >
                <s.icon className="h-4 w-4" />
              </span>
               <div className="min-w-0 leading-tight">
                 <div className="text-[10px] font-medium uppercase text-muted-foreground">
                  {s.label}
                </div>
                 <div className={`mt-1 break-words font-display text-base font-bold ${toneText[s.tone]}`}>
                  {s.value}
                </div>
              </div>
            </Link>
          </li>
        ))}
      </ul>
      </div>
    </section>
  );
}

function relTime(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 1) return "baru saja";
  if (m < 60) return `${m}m lalu`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}j lalu`;
  return `${Math.floor(h / 24)}h lalu`;
}

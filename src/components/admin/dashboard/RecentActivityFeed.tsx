// Ringkasan lima aktivitas terbaru untuk Super Admin.
import { Activity, ArrowRight, RefreshCw } from "lucide-react";
import { Link } from "@tanstack/react-router";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

export type ActivityRow = {
  id: string;
  action: string;
  actor: string | null;
  resource_type: string | null;
  resource_id: string | null;
  user_id: string | null;
  metadata: unknown;
  payload: unknown;
  submission_id: string | null;
  workflow_id: string | null;
  created_at: string;
};

type RecentActivityFeedProps = {
  rows: ActivityRow[];
  error?: boolean;
  onRetry?: () => void;
};

export function RecentActivityFeed({ rows, error = false, onRetry }: RecentActivityFeedProps) {
  const visibleRows = rows.slice(0, 5);
  return (
    <section aria-labelledby="recent-activity-title" className="h-full rounded-lg border border-border bg-card p-4 shadow-soft">
      <div className="mb-1 flex flex-wrap items-center justify-between gap-2 border-b border-border pb-3">
        <div className="flex items-center gap-2">
          <span className="grid h-8 w-8 place-items-center rounded-md bg-primary-soft text-primary" aria-hidden="true">
            <Activity className="h-4 w-4" />
          </span>
          <div>
            <h2 id="recent-activity-title" className="font-display text-sm font-semibold text-foreground">Aktivitas Terbaru</h2>
            <p className="text-[11px] text-muted-foreground">Lima catatan terakhir sistem</p>
          </div>
        </div>
        <Link
          to="/admin/audit"
          className="inline-flex min-h-10 items-center gap-1 rounded-md px-2 text-xs font-semibold text-primary transition-colors hover:bg-primary-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          Lihat semua <ArrowRight className="h-3 w-3" />
        </Link>
      </div>
      {error ? (
        <div className="my-4 flex min-h-28 flex-col items-center justify-center rounded-md border border-dashed border-border bg-surface px-4 py-6 text-center">
          <p className="text-sm font-semibold text-foreground">Aktivitas tidak dapat dimuat.</p>
          {onRetry && (
            <Button type="button" variant="outline" size="sm" className="mt-3" onClick={onRetry}>
              <RefreshCw className="h-3.5 w-3.5" /> Coba lagi
            </Button>
          )}
        </div>
      ) : rows.length === 0 ? (
        <div className="my-4 flex min-h-28 items-center justify-center rounded-md border border-dashed border-border bg-surface px-4 py-6 text-center text-sm text-muted-foreground">
          Belum ada aktivitas tercatat.
        </div>
      ) : (
        <ol className="divide-y divide-border" aria-label="Daftar aktivitas terbaru">
          {visibleRows.map((r) => {
            const presentation = presentActivity(r);
            return (
              <li key={r.id} className="relative grid grid-cols-[2.75rem_minmax(0,1fr)] gap-3 py-3.5 first:pt-3 sm:grid-cols-[3.25rem_minmax(0,1fr)]">
                <div className="relative flex justify-end pt-0.5">
                  <time
                    dateTime={r.created_at}
                    title={fullDate(r.created_at)}
                    className="text-[11px] font-bold tabular-nums text-muted-foreground"
                  >
                    {clock(r.created_at)}
                  </time>
                </div>
                <div className="relative min-w-0 border-l border-border pl-4">
                  <span className="absolute -left-[5px] top-1 h-2.5 w-2.5 rounded-full border-2 border-card bg-primary" aria-hidden="true" />
                  <div className="flex min-w-0 flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                    <p className="min-w-0 text-sm font-semibold leading-5 text-foreground">{presentation.label}</p>
                    {presentation.status && <StatusBadge status={presentation.status} />}
                  </div>
                  <div className="mt-1 flex flex-wrap items-center gap-x-1.5 gap-y-0.5 text-[11px] leading-4 text-muted-foreground">
                    {presentation.module && <span>{presentation.module}</span>}
                    {presentation.context && presentation.context !== presentation.module && (
                      <><span aria-hidden="true">·</span><span>{presentation.context}</span></>
                    )}
                    {presentation.actor && (
                      <><span aria-hidden="true">·</span><span>{presentation.actor}</span></>
                    )}
                    <span aria-hidden="true">·</span>
                    <span>{rel(r.created_at)}</span>
                  </div>
                </div>
              </li>
            );
          })}
        </ol>
      )}
    </section>
  );
}

const activityLabels: Record<string, string> = {
  "dashboard.view": "Membuka Dashboard",
  "monitoring.view": "Membuka Monitoring",
  "dashboard.export": "Mengekspor Data Dashboard",
  "profile.update": "Data pengguna diperbarui",
  "permohonan.create": "Permohonan layanan masuk",
  "permohonan.update": "Permohonan layanan diperbarui",
  "user.approve": "Pengguna baru disetujui",
  "workflow.create": "Alur kerja dibuat",
  "workflow.update": "Alur kerja diperbarui",
  "workflow.publish": "Alur kerja diterbitkan",
  "workflow.archive": "Alur kerja diarsipkan",
  "workflow.clone": "Alur kerja disalin",
  "template.create": "Template dibuat",
  "template.publish": "Template diterbitkan",
  "template.archive": "Template diarsipkan",
};

const moduleLabels: Record<string, string> = {
  overview: "Ringkasan Dashboard",
  workflow: "Monitoring Alur Kerja",
  tasks: "Monitoring Tugas",
  health: "Kesehatan Sistem",
};

const resourceLabels: Record<string, string> = {
  dashboard: "Dashboard",
  workflow: "Alur Kerja",
  workflow_version: "Versi Alur Kerja",
  workflow_template: "Template Alur Kerja",
  workflow_node: "Tahapan Alur Kerja",
  workflow_edge: "Relasi Alur Kerja",
  permohonan: "Pelayanan Publik",
  profile: "Pengguna & Hak Akses",
};

type ActivityStatus = "Berhasil" | "Menunggu" | "Gagal" | "Diproses" | "Dibatalkan";

const statusLabels: Record<string, ActivityStatus> = {
  success: "Berhasil",
  succeeded: "Berhasil",
  completed: "Berhasil",
  pending: "Menunggu",
  waiting: "Menunggu",
  failed: "Gagal",
  error: "Gagal",
  processing: "Diproses",
  in_progress: "Diproses",
  cancelled: "Dibatalkan",
  canceled: "Dibatalkan",
};

function presentActivity(row: ActivityRow) {
  const raw = row.action.trim();
  const metadata = asRecord(row.metadata);
  const payload = asRecord(row.payload);
  const moduleKey = textValue(metadata.module);
  const rawStatus = textValue(metadata.status) ?? textValue(payload.status);
  const contextSource = row.resource_type?.trim() || null;
  const actorLabel = textValue(metadata.actor_name) ?? textValue(metadata.actor_role) ?? textValue(metadata.actor_label);

  return {
    label: activityLabels[raw] ?? humanize(raw),
    // `actor` dan `user_id` pada tabel adalah UUID. Tampilkan aktor hanya bila
    // penulis event memang menyimpan label yang siap dibaca di metadata.
    actor: actorLabel,
    module: moduleKey ? (moduleLabels[moduleKey] ?? humanize(moduleKey)) : null,
    context: contextSource ? (resourceLabels[contextSource] ?? humanize(contextSource)) : null,
    status: rawStatus ? (statusLabels[rawStatus.toLowerCase()] ?? null) : null,
  };
}

function StatusBadge({ status }: { status: ActivityStatus }) {
  const tone = status === "Berhasil"
    ? "border-success/25 bg-success/10 text-success"
    : status === "Gagal" || status === "Dibatalkan"
      ? "border-destructive/25 bg-destructive/10 text-destructive"
      : "border-gold/30 bg-gold/15 text-gold-foreground";

  return <Badge variant="outline" className={`w-fit shrink-0 px-2 py-0 text-[10px] ${tone}`}>{status}</Badge>;
}

function asRecord(value: unknown): Record<string, unknown> {
  return value != null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

function textValue(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function humanize(value: string): string {
  const normalized = value.replace(/[._-]+/g, " ").trim();
  return normalized ? normalized.replace(/^./, (letter) => letter.toUpperCase()) : "Aktivitas sistem";
}

function clock(iso: string): string {
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? "—" : date.toLocaleTimeString("id-ID", { hour: "2-digit", minute: "2-digit" });
}

function fullDate(iso: string): string {
  const date = new Date(iso);
  return Number.isNaN(date.getTime())
    ? "Waktu tidak tersedia"
    : date.toLocaleString("id-ID", { dateStyle: "long", timeStyle: "short" });
}

function rel(iso: string): string {
  const timestamp = new Date(iso).getTime();
  if (Number.isNaN(timestamp)) return "waktu tidak tersedia";
  const d = Math.max(0, Date.now() - timestamp);
  const m = Math.floor(d / 60000);
  if (m < 1) return "baru saja";
  if (m < 60) return `${m}m lalu`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}j lalu`;
  return `${Math.floor(h / 24)}h lalu`;
}

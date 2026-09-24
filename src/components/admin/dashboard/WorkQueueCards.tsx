// Zona B — Antrian kerja, dipisah jadi 2 grup: "Perlu Anda Tindak" & "Perlu Perhatian".
import { Link } from "@tanstack/react-router";
import { ArrowRight, CheckCircle2, ClipboardCheck, ListChecks, ScanLine, Timer } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { DashboardSectionHeader } from "./DashboardSectionHeader";

export type WorkItem = {
  label: string;
  count: number;
  to: string;
  desc: string;
  icon: LucideIcon;
  urgent?: boolean;
};

interface Props {
  pendingApproval: number;
  pendingVerifikasi: number | null;
  pendingReview: number;
  overdueTasks: number;
}

export function WorkQueueCards(p: Props) {
  const action: WorkItem[] = [
    {
      label: "Persetujuan Akun",
      count: p.pendingApproval,
      to: "/admin/approvals",
      desc: "Pengguna menunggu persetujuan",
      icon: ClipboardCheck,
    },
    {
      label: "Verifikasi Akun",
      count: p.pendingVerifikasi ?? 0,
      to: "/admin/verifikasi",
      desc: p.pendingVerifikasi == null ? "Sumber data perlu dikonfirmasi" : "Warga/ASN belum diverifikasi",
      icon: ScanLine,
    },
    {
      label: "Review Pengisian Form",
      count: p.pendingReview,
      to: "/admin/submission-review",
      desc: "Menunggu peninjauan",
      icon: ListChecks,
    },
  ];
  const attention: WorkItem[] = [
    {
      label: "Lewat Tenggat",
      count: p.overdueTasks,
      to: "/admin/monitoring/tasks",
      desc: "Workflow lewat tenggat / dieskalasi",
      icon: Timer,
      urgent: p.overdueTasks > 0,
    },
  ];

  const totalAction = action.reduce((s, i) => s + i.count, 0);
  const totalAttn = attention.reduce((s, i) => s + i.count, 0);

  return (
    <section aria-labelledby="work-queue-title" className="mb-6">
      <DashboardSectionHeader
        eyebrow="Tindakan berikutnya"
        title="Antrean Prioritas"
        description={totalAction + totalAttn === 0
            ? "Semua kategori prioritas yang tersedia berada dalam kondisi normal."
            : `${totalAction + totalAttn} item memerlukan tinjauan atau tindakan.`}
      />
      {totalAction + totalAttn === 0 && (
        <div className="mb-3 grid grid-cols-[auto_minmax(0,1fr)] items-center gap-3 rounded-lg border border-success/25 bg-success/10 px-4 py-3 text-success">
          <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-card"><CheckCircle2 className="h-4 w-4" /></span>
          <div className="min-w-0">
            <p className="text-sm font-semibold">Tidak ada pekerjaan prioritas saat ini</p>
            <p className="text-xs text-muted-foreground">Semua workflow berjalan sesuai kondisi normal.</p>
          </div>
        </div>
      )}
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {[...attention, ...action].map((item) => (
          <Card key={item.label} item={item} unavailable={item.label === "Verifikasi Akun" && p.pendingVerifikasi == null} />
        ))}
      </div>
    </section>
  );
}

function Card({ item: it, unavailable = false }: { item: WorkItem; unavailable?: boolean }) {
  const hot = it.count > 0;
  const urgent = it.urgent && it.count > 0;
  return (
    <Link
      to={it.to}
      aria-label={`${it.label}: ${unavailable ? "data belum tersedia" : `${it.count} item`}. ${it.desc}`}
      className={`group flex min-h-32 flex-col gap-3 rounded-md border p-4 transition hover:border-primary/50 hover:bg-surface ${
        urgent
          ? "border-destructive/40 bg-destructive/5"
          : hot
            ? "border-primary/30 bg-card"
            : unavailable ? "border-dashed border-border bg-surface/40" : "border-border bg-card"
      }`}
    >
      <div className="flex items-center justify-between">
        <span
          className={`grid h-8 w-8 place-items-center rounded-md ${
            urgent
              ? "bg-destructive/10 text-destructive"
              : hot
                ? "bg-primary/10 text-primary"
                : "bg-surface text-muted-foreground"
          }`}
        >
          <it.icon className="h-4 w-4" />
        </span>
        <span
          className={`font-display text-2xl font-bold tabular-nums ${
             urgent ? "text-destructive" : hot ? "text-primary" : unavailable ? "text-muted-foreground" : "text-foreground"
          }`}
        >
          {unavailable ? "—" : it.count.toLocaleString("id-ID")}
        </span>
      </div>
      <div>
        <div className="text-sm font-semibold text-foreground">{it.label}</div>
        <div className="text-[11px] text-muted-foreground">{it.desc}</div>
      </div>
        <div className="mt-auto inline-flex min-h-8 items-center gap-1 text-xs font-semibold text-primary">
        Tinjau <ArrowRight className="h-3 w-3 transition-transform group-hover:translate-x-0.5" />
      </div>
    </Link>
  );
}

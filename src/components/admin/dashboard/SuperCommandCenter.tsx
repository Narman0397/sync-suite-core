// Wrapper: kumpulan zona Command Center untuk Super Admin.
// Mengambil semua data ringkas via supabase client (count-only) + RPC ringan.
import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { HealthBar } from "./HealthBar";
import { WorkQueueCards } from "./WorkQueueCards";
import { EcosystemGrid, type EcosystemData } from "./EcosystemGrid";
import { RecentActivityFeed, type ActivityRow } from "./RecentActivityFeed";
import { OnboardingHint } from "./OnboardingHint";
import { DashboardDataNotice } from "./DashboardDataNotice";
import { DashboardLoadingState } from "./DashboardLoadingState";
import { Button } from "@/components/ui/button";

import { Building2, CalendarClock, CheckCircle2, Inbox, Lightbulb, ListTodo, RefreshCw, ShieldCheck } from "lucide-react";

type SummaryShape = {
  kpi?: { baru: number; diproses: number; selesai: number; ditolak: number; total: number };
  trend?: { key: string; masuk: number; selesai: number }[];
  sla?: { nama: string; total: number; on_time: number }[];
  backlog?: { singkatan: string | null; nama: string | null; baru: number; diproses: number }[];
};

type State = {
  loaded: boolean;
  // Health
  systemScore: number | null;
  systemTone: "ok" | "warn" | "crit" | "info";
  jobsPending: number;
  jobsFailed: number;
  jobsRunning: number;
  alertsCount: number;
  backupAgeHours: number | null;
  lastActivity: string | null;
  // Work queue
  pendingApproval: number;
  pendingVerifikasi: number | null;
  pendingReview: number;
  overdueTasks: number;
  // Ecosystem
  eco: EcosystemData;
  // Activity
  activity: ActivityRow[];
  activityError: boolean;
};

const emptyEco: EcosystemData = {
  layananSpark: [],
  layanan: { total: 0, today: 0, slaOnTime: null, rating: null },
  kinerjaOpd: { opdAktif: 0, pejabat: 0, backlogTopName: null, backlogTopCount: 0 },
  data: { datasetAktif: 0, submission: 0, review: 0 },
  asn: { totalAsn: 0, hadirHariIni: null, izinPending: 0 },
  aset: { totalAset: 0, opnameAktif: 0, warrantyExp: null },
};

export function SuperCommandCenter({ summary }: { summary: SummaryShape | undefined }) {
  const [updatedAt, setUpdatedAt] = useState<Date | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);
  const [loadError, setLoadError] = useState(false);
  const [s, setS] = useState<State>({
    loaded: false,
    systemScore: null,
    systemTone: "info",
    jobsPending: 0,
    jobsFailed: 0,
    jobsRunning: 0,
    alertsCount: 0,
    backupAgeHours: null,
    lastActivity: null,
    pendingApproval: 0,
    pendingVerifikasi: null,
    pendingReview: 0,
    overdueTasks: 0,
    eco: emptyEco,
    activity: [],
    activityError: false,
  });

  useEffect(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayIso = today.toISOString();
    const nowIso = new Date().toISOString();

    (async () => {
      setLoadError(false);
      const [
        jobsPending,
        jobsFailed,
        jobsRunning,
        deadLetter,
        pendingApproval,
        pendingReview,
        overdueTasks,
        permTotal,
        permToday,
        datasetAktif,
        datasetSubs,
        datasetReview,
        opdAktif,
        pejabatCount,
        asnTotal,
        izinPending,
        asetTotal,
        opnameAktif,
        ratingAvg,
        backupSnap,
        activity,
        absensiToday,
      ] = await Promise.all([
        supabase.from("job_queue").select("id", { count: "exact", head: true }).eq("status", "pending"),
        supabase.from("job_queue").select("id", { count: "exact", head: true }).in("status", ["failed"]),
        supabase.from("job_queue").select("id", { count: "exact", head: true }).eq("status", "running"),
        supabase.from("dead_letter_jobs").select("id", { count: "exact", head: true }),
        supabase
          .from("profiles")
          .select("id", { count: "exact", head: true })
          .eq("verification_status", "pending"),
        supabase
          .from("form_submissions")
          .select("id", { count: "exact", head: true })
          .in("status", ["submitted", "under_review"]),
        supabase
          .from("submission_tasks")
          .select("id", { count: "exact", head: true })
          .in("status", ["pending", "in_progress", "escalated"])
          .lt("due_at", nowIso),
        supabase.from("permohonan").select("id", { count: "exact", head: true }),
        supabase
          .from("permohonan")
          .select("id", { count: "exact", head: true })
          .gte("tanggal_masuk", todayIso),
        supabase.from("dataset_template").select("id", { count: "exact", head: true }).eq("aktif", true),
        supabase.from("dataset_submission").select("id", { count: "exact", head: true }),
        supabase
          .from("dataset_submission")
          .select("id", { count: "exact", head: true })
          .eq("review_status", "pending"),
        supabase.from("opd").select("id", { count: "exact", head: true }),
        supabase.from("pejabat").select("id", { count: "exact", head: true }),
        supabase
          .from("user_roles")
          .select("user_id", { count: "exact", head: true })
          .eq("role", "asn"),
        supabase
          .from("pengajuan_izin")
          .select("id", { count: "exact", head: true })
          .eq("status", "pending"),
        supabase.from("aset").select("id", { count: "exact", head: true }),
        supabase
          .from("aset_opname")
          .select("id", { count: "exact", head: true })
          .in("status", ["open", "in_progress", "draft"]),
        supabase.from("permohonan_rating").select("skor"),
        supabase
          .from("backup_snapshot")
          .select("created_at")
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle(),
        supabase
          .from("workflow_audit_logs")
          .select("id,action,actor,resource_type,resource_id,user_id,metadata,payload,submission_id,workflow_id,created_at")
          .order("created_at", { ascending: false })
          .limit(5),
        supabase
          .from("absensi_asn")
          .select("user_id", { count: "exact", head: true })
          .gte("waktu", todayIso)
          .eq("tipe", "masuk"),
      ]);

      const ratingValues = ((ratingAvg.data ?? []) as { skor: number }[])
        .map((r) => r.skor)
        .filter((n) => typeof n === "number");
      const ratingMean =
        ratingValues.length > 0
          ? ratingValues.reduce((a, b) => a + b, 0) / ratingValues.length
          : null;

      const backupAge = backupSnap.data?.created_at
        ? Math.round((Date.now() - new Date(backupSnap.data.created_at).getTime()) / 3_600_000)
        : null;

      const totalFailed = (jobsFailed.count ?? 0) + (deadLetter.count ?? 0);
      const alerts =
        (totalFailed > 0 ? 1 : 0) +
        ((overdueTasks.count ?? 0) > 0 ? 1 : 0);

      // Skor sistem sederhana (0-100) berbasis sinyal yang ada.
      let score = 100;
      if (totalFailed > 0) score -= Math.min(30, totalFailed * 2);
      if ((overdueTasks.count ?? 0) > 0) score -= Math.min(20, (overdueTasks.count ?? 0));
      if (backupAge != null && backupAge > 48) score -= 15;
      if (backupAge == null) score -= 5;
      score = Math.max(0, score);
      const systemTone: State["systemTone"] = score >= 85 ? "ok" : score >= 60 ? "warn" : "crit";

      setS({
        loaded: true,
        systemScore: score,
        systemTone,
        jobsPending: jobsPending.count ?? 0,
        jobsFailed: totalFailed,
        jobsRunning: jobsRunning.count ?? 0,
        alertsCount: alerts,
        backupAgeHours: backupAge,
        lastActivity: (activity.data?.[0] as ActivityRow | undefined)?.created_at ?? null,
        pendingApproval: pendingApproval.count ?? 0,
        pendingVerifikasi: null,
        pendingReview: pendingReview.count ?? 0,
        overdueTasks: overdueTasks.count ?? 0,
        eco: {
          layananSpark: [],
          layanan: {
            total: permTotal.count ?? 0,
            today: permToday.count ?? 0,
            slaOnTime: null,
            rating: ratingMean,
          },
          kinerjaOpd: {
            opdAktif: opdAktif.count ?? 0,
            pejabat: pejabatCount.count ?? 0,
            backlogTopName: null,
            backlogTopCount: 0,
          },
          data: {
            datasetAktif: datasetAktif.count ?? 0,
            submission: datasetSubs.count ?? 0,
            review: datasetReview.count ?? 0,
          },
          asn: {
            totalAsn: asnTotal.count ?? 0,
            hadirHariIni: absensiToday.count ?? 0,
            izinPending: izinPending.count ?? 0,
          },
          aset: {
            totalAset: asetTotal.count ?? 0,
            opnameAktif: opnameAktif.count ?? 0,
            warrantyExp: null,
          },
        },
        activity: (activity.data ?? []) as ActivityRow[],
        activityError: Boolean(activity.error),
      });
      setUpdatedAt(new Date());
    })().catch(() => {
      setLoadError(true);
    });
  }, [refreshKey]);

  // Layer in summary RPC enrichment (sparkline, sla, top backlog).
  const eco: EcosystemData = {
    ...s.eco,
    layananSpark: summary?.trend?.map((t) => ({ value: t.masuk })) ?? [],
    layanan: {
      ...s.eco.layanan,
      slaOnTime:
        summary?.sla && summary.sla.length > 0
          ? Math.round(
              (summary.sla.reduce((a, b) => a + b.on_time, 0) /
                Math.max(
                  1,
                  summary.sla.reduce((a, b) => a + b.total, 0),
                )) *
                100,
            )
          : null,
    },
    kinerjaOpd: {
      ...s.eco.kinerjaOpd,
      backlogTopName:
        summary?.backlog && summary.backlog.length > 0
          ? (summary.backlog[0].singkatan ?? summary.backlog[0].nama ?? "—")
          : null,
      backlogTopCount:
        summary?.backlog && summary.backlog.length > 0
          ? (summary.backlog[0].baru ?? 0) + (summary.backlog[0].diproses ?? 0)
          : 0,
    },
  };

  const priorityCount = s.pendingApproval + s.pendingReview + s.overdueTasks + (s.pendingVerifikasi ?? 0);
  const summaryItems = [
    {
      label: "Total Permohonan",
      value: eco.layanan.total,
      detail: `${eco.layanan.today.toLocaleString("id-ID")} masuk hari ini`,
      icon: Inbox,
      tone: "bg-primary/10 text-primary",
    },
    {
      label: "Masuk Hari Ini",
      value: eco.layanan.today,
      detail: "Permohonan tercatat",
      icon: CalendarClock,
      tone: "bg-surface text-muted-foreground",
    },
    {
      label: "OPD Aktif",
      value: eco.kinerjaOpd.opdAktif,
      detail: `${eco.kinerjaOpd.pejabat.toLocaleString("id-ID")} pejabat tercatat`,
      icon: Building2,
      tone: "bg-surface text-muted-foreground",
    },
    {
      label: "Perlu Tinjauan",
      value: priorityCount,
      detail: priorityCount === 0 ? "Kategori tersedia normal" : "Item prioritas aktif",
      icon: ListTodo,
      tone: priorityCount > 0 ? "bg-gold/15 text-gold-foreground" : "bg-surface text-muted-foreground",
    },
  ];

  if (!s.loaded && !loadError) {
    return <DashboardLoadingState />;
  }

  if (!s.loaded && loadError) {
    return (
      <div className="space-y-4">
        <DashboardDataNotice message="Ringkasan operasional belum dapat dimuat. Coba segarkan kembali." />
        <Button type="button" variant="outline" size="sm" onClick={() => setRefreshKey((key) => key + 1)}>
          <RefreshCw className="h-3.5 w-3.5" /> Coba lagi
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-0">
      <div className="mb-5 grid grid-cols-[minmax(0,1fr)_auto] items-center gap-3 rounded-md border border-border bg-surface/50 px-3 py-2 text-xs text-muted-foreground">
        <div className="inline-flex flex-wrap items-center gap-x-3 gap-y-1">
          <span className="inline-flex items-center gap-2">
            <span className={`h-2 w-2 rounded-full ${s.loaded && !loadError ? "bg-success" : loadError ? "bg-destructive" : "bg-gold"}`} />
            <span className="font-semibold uppercase tracking-wide text-foreground">
              {loadError ? "Sebagian data gagal" : "Sistem terhubung"}
            </span>
          </span>
          <span className="hidden h-3 w-px bg-border sm:block" />
          <span>
            {updatedAt
              ? `Diperbarui ${updatedAt.toLocaleTimeString("id-ID", { hour: "2-digit", minute: "2-digit" })}`
              : "Memuat data…"}
          </span>
        </div>
        <Button type="button" variant="outline" size="sm" onClick={() => setRefreshKey((key) => key + 1)} disabled={!s.loaded && !loadError}>
          <RefreshCw className="h-3.5 w-3.5" /> Segarkan
        </Button>
      </div>
      {loadError && <div className="mb-4"><DashboardDataNotice message="Sebagian ringkasan gagal dimuat. Segarkan untuk mencoba kembali." /></div>}

      <div className="flex flex-col">
      <section aria-labelledby="today-summary-title" className="order-2 mb-7 lg:order-1">
        <div className="mb-3 flex items-end justify-between gap-4">
          <div>
            <p className="text-[10px] font-bold uppercase text-primary">Executive summary</p>
            <h2 id="today-summary-title" className="mt-0.5 font-display text-lg font-bold text-foreground">Ringkasan Hari Ini</h2>
          </div>
          <p className="hidden text-xs text-muted-foreground sm:block">Data operasional terkini</p>
        </div>
        <div className="grid overflow-hidden rounded-lg border border-border bg-card shadow-soft sm:grid-cols-2 xl:grid-cols-4">
          {summaryItems.map((item) => (
            <div key={item.label} className="grid min-w-0 grid-cols-[auto_minmax(0,1fr)] items-center gap-3 border-b border-border p-4 last:border-b-0 sm:[&:nth-child(odd)]:border-r sm:[&:nth-child(n+3)]:border-b-0 xl:border-b-0 xl:border-r xl:last:border-r-0">
              <span className={`grid h-10 w-10 shrink-0 place-items-center rounded-md ${item.tone}`}><item.icon className="h-5 w-5" /></span>
              <div className="min-w-0">
                <p className="text-[11px] font-semibold uppercase text-muted-foreground">{item.label}</p>
                <div className="mt-0.5 flex flex-wrap items-baseline gap-x-2">
                  <strong className="font-display text-2xl tabular-nums text-foreground">{item.value.toLocaleString("id-ID")}</strong>
                  <span className="text-[10px] text-muted-foreground">{item.detail}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      <div className="order-1 lg:order-2">
      <HealthBar
        systemTone={s.systemTone}
        systemScore={s.systemScore}
        jobsPending={s.jobsPending}
        jobsFailed={s.jobsFailed}
        jobsRunning={s.jobsRunning}
        alertsCount={s.alertsCount}
        backupAgeHours={s.backupAgeHours}
        lastActivity={s.lastActivity}
      />
      </div>
      </div>
      <WorkQueueCards
        pendingApproval={s.pendingApproval}
        pendingVerifikasi={s.pendingVerifikasi}
        pendingReview={s.pendingReview}
        overdueTasks={s.overdueTasks}
      />
      <EcosystemGrid {...eco} />
      <div className="mb-6 grid gap-4 lg:grid-cols-[minmax(0,2fr)_minmax(260px,1fr)]">
        <RecentActivityFeed
          rows={s.activity}
          error={s.activityError}
          onRetry={() => setRefreshKey((key) => key + 1)}
        />
        <div className="space-y-4">
          <div className="rounded-lg border border-border bg-card p-4 shadow-soft">
            <div className="flex items-center gap-2">
              <span className="grid h-8 w-8 place-items-center rounded-md bg-primary-soft text-primary"><Lightbulb className="h-4 w-4" /></span>
              <div>
                <h2 className="font-display text-sm font-semibold text-foreground">Tips & Informasi</h2>
                <p className="text-[11px] text-muted-foreground">Panduan singkat operasional</p>
              </div>
            </div>
            <div className={`mt-4 grid grid-cols-[auto_minmax(0,1fr)] gap-2.5 rounded-md px-3 py-3 ${s.systemTone === "ok" ? "bg-success/10 text-success" : "bg-gold/15 text-gold-foreground"}`}>
              {s.systemTone === "ok" ? <CheckCircle2 className="mt-0.5 h-4 w-4" /> : <ShieldCheck className="mt-0.5 h-4 w-4" />}
              <div>
                <p className="text-xs font-semibold">{s.systemTone === "ok" ? "Sistem berjalan normal" : "Sistem perlu ditinjau"}</p>
                <p className="mt-0.5 text-[11px] text-muted-foreground">{s.systemTone === "ok" ? "Tidak ada gangguan utama yang terdeteksi saat ini." : `${s.alertsCount} indikator operasional memerlukan perhatian.`}</p>
              </div>
            </div>
            <ul className="mt-2 divide-y divide-border text-xs text-muted-foreground">
              {s.jobsFailed > 0 && <li className="py-2.5">Tinjau pekerjaan gagal dan dead-letter sebelum memproses antrean lain.</li>}
              {s.backupAgeHours == null && <li className="py-2.5">Status cadangan data belum tersedia.</li>}
              {s.backupAgeHours != null && s.backupAgeHours > 26 && <li className="py-2.5">Cadangan data terakhir perlu ditinjau.</li>}
              <li className="py-2.5 last:pb-0">Gunakan log audit untuk menelusuri perubahan penting.</li>
            </ul>
          </div>
          <OnboardingHint />
        </div>
      </div>
    </div>
  );
}

export { RecentActivityFeed };


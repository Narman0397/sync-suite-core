// Halaman Permohonan (Pelayanan Publik) — KPI, tren, distribusi, insight & daftar.
import { useEffect, useMemo, useState, lazy, Suspense } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import {
  Inbox,
  Loader2,
  CheckCircle2,
  XCircle,
  Search,
  Filter,
  ArrowUpRight,
  Trash2,
  Building2,
  Clock,
  ShieldCheck,
  AlertTriangle,
} from "lucide-react";
import { toast } from "sonner";
import { AdminShell, StatCard } from "@/components/admin/AdminShell";
import { AdminGuard } from "@/components/admin/AdminGuard";
import { useAuth } from "@/lib/auth-context";
import { supabase } from "@/integrations/supabase/client";
import { deletePermohonan } from "@/lib/admin-actions.functions";
import { listAdminPermohonan } from "@/lib/permohonan-list.functions";
import { useServerFn } from "@tanstack/react-start";
import { STATUS_LABEL, STATUS_TONE, fmtTanggal, type StatusPermohonan } from "@/lib/permohonan";
import { dashboardSummaryQueryOptions } from "@/lib/queries.dashboard";

const AdminTrendChart = lazy(() => import("./-admin-trend-chart"));
const AdminKategoriChart = lazy(() => import("./-admin-kategori-chart"));
const AdminStatusPie = lazy(() => import("./-admin-status-pie"));
const ChartFallback = () => (
  <div className="grid h-full place-items-center text-xs text-muted-foreground">Memuat grafik…</div>
);

export const Route = createFileRoute("/_authenticated/admin/permohonan")({
  head: () => ({
    meta: [{ title: "Permohonan — Admin" }, { name: "robots", content: "noindex" }],
  }),
  component: () => (
    <AdminGuard>
      <PermohonanPage />
    </AdminGuard>
  ),
});

type Permohonan = {
  id: string;
  kode: string;
  judul: string;
  kategori: string;
  status: StatusPermohonan;
  tanggal_masuk: string;
  tenggat: string | null;
  updated_at: string;
  opd_id: string;
  pemohon_id: string;
};
type Opd = { id: string; nama: string; singkatan: string; kategori: string[] };

const STATUS_OPTIONS: ("semua" | StatusPermohonan)[] = [
  "semua",
  "baru",
  "diproses",
  "selesai",
  "ditolak",
];

function PermohonanPage() {
  const { isSuperAdmin, user } = useAuth();
  const [opdList, setOpdList] = useState<Opd[]>([]);
  const [opdAktifId, setOpdAktifId] = useState<string>("");
  const [items, setItems] = useState<Permohonan[]>([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState<"semua" | StatusPermohonan>("semua");
  const [kategori, setKategori] = useState<string>("semua");
  const [q, setQ] = useState("");
  const [sysStat, setSysStat] = useState<{
    jobs: { pending: number; failed: number; running: number };
    users: number;
    berita: number;
    layanan: number;
  } | null>(null);
  const [slaMap, setSlaMap] = useState<Map<string, number>>(new Map());

  useEffect(() => {
    supabase
      .from("opd")
      .select("id,nama,singkatan,kategori")
      .order("nama")
      .then(({ data }) => setOpdList((data ?? []) as Opd[]));
  }, []);

  useEffect(() => {
    if (!user) return;
    if (!isSuperAdmin) {
      supabase
        .from("profiles")
        .select("opd_id")
        .eq("id", user.id)
        .maybeSingle()
        .then(({ data }) => setOpdAktifId(data?.opd_id ?? ""));
    }
  }, [user, isSuperAdmin]);

  const fetchList = useServerFn(listAdminPermohonan);
  useEffect(() => {
    setLoading(true);
    fetchList({ data: { opd_id: opdAktifId || null } })
      .then((res) => {
        setItems((res.rows ?? []) as Permohonan[]);
      })
      .catch(() => setItems([]))
      .finally(() => setLoading(false));
  }, [opdAktifId, fetchList]);

  const summaryQ = useQuery({
    ...dashboardSummaryQueryOptions(opdAktifId || null, 14),
    enabled: isSuperAdmin || !!opdAktifId,
  });
  const summary = summaryQ.data;

  const opd = opdList.find((o) => o.id === opdAktifId);

  const filtered = useMemo(
    () =>
      items.filter((p) => {
        if (status !== "semua" && p.status !== status) return false;
        if (kategori !== "semua" && p.kategori !== kategori) return false;
        if (q.trim()) {
          const n = q.toLowerCase();
          if (!p.kode.toLowerCase().includes(n) && !p.judul.toLowerCase().includes(n)) return false;
        }
        return true;
      }),
    [items, status, kategori, q],
  );

  const kpi = useMemo(() => {
    if (summary?.kpi) {
      return {
        baru: summary.kpi.baru,
        diproses: summary.kpi.diproses,
        selesai: summary.kpi.selesai,
        ditolak: summary.kpi.ditolak,
      };
    }
    const c: Record<string, number> = { baru: 0, diproses: 0, selesai: 0, ditolak: 0 };
    items.forEach((p) => {
      if (p.status in c) c[p.status]++;
    });
    return c;
  }, [items, summary]);

  const trend = useMemo(() => {
    if (summary?.trend?.length) {
      return summary.trend.map((t) => ({
        label: new Date(t.key).toLocaleDateString("id-ID", { day: "2-digit", month: "short" }),
        key: t.key,
        masuk: t.masuk,
        selesai: t.selesai,
      }));
    }
    const days: { label: string; key: string; masuk: number; selesai: number }[] = [];
    const now = new Date();
    for (let i = 13; i >= 0; i--) {
      const d = new Date(now.getTime() - i * 86400000);
      const key = d.toISOString().slice(0, 10);
      days.push({
        label: d.toLocaleDateString("id-ID", { day: "2-digit", month: "short" }),
        key,
        masuk: 0,
        selesai: 0,
      });
    }
    const map = new Map(days.map((d) => [d.key, d]));
    items.forEach((p) => {
      const k = p.tanggal_masuk.slice(0, 10);
      const row = map.get(k);
      if (row) row.masuk++;
      if (p.status === "selesai" && row) row.selesai++;
    });
    return days;
  }, [items, summary]);

  const distribusiKategori = useMemo(() => {
    if (summary?.kategori?.length) return summary.kategori;
    const m = new Map<string, number>();
    items.forEach((p) => m.set(p.kategori, (m.get(p.kategori) ?? 0) + 1));
    return Array.from(m, ([nama, jumlah]) => ({ nama, jumlah }))
      .sort((a, b) => b.jumlah - a.jumlah)
      .slice(0, 8);
  }, [items, summary]);

  useEffect(() => {
    if (!isSuperAdmin) return;
    (async () => {
      const [kat, jobsPending, jobsFailed, jobsRunning, usrCount, berCount, layCount] =
        await Promise.all([
          supabase.from("kategori_layanan").select("nama,sla_hari"),
          supabase.from("job_queue").select("id", { count: "exact", head: true }).eq("status", "pending"),
          supabase.from("job_queue").select("id", { count: "exact", head: true }).in("status", ["failed", "dead"]),
          supabase.from("job_queue").select("id", { count: "exact", head: true }).eq("status", "running"),
          supabase.from("profiles").select("id", { count: "exact", head: true }),
          supabase.from("berita").select("id", { count: "exact", head: true }),
          supabase.from("layanan_publik").select("id", { count: "exact", head: true }),
        ]);
      const m = new Map<string, number>();
      (kat.data ?? []).forEach((k) => m.set(k.nama, k.sla_hari));
      setSlaMap(m);
      setSysStat({
        jobs: {
          pending: jobsPending.count ?? 0,
          failed: jobsFailed.count ?? 0,
          running: jobsRunning.count ?? 0,
        },
        users: usrCount.count ?? 0,
        berita: berCount.count ?? 0,
        layanan: layCount.count ?? 0,
      });
    })().catch(() => {});
  }, [isSuperAdmin]);

  const slaPerformance = useMemo(() => {
    if (!isSuperAdmin) return [];
    if (summary?.sla?.length) {
      return summary.sla.map((s) => ({
        nama: s.nama,
        persen: s.total ? Math.round((s.on_time / s.total) * 100) : 0,
        total: s.total,
        targetDays: null as number | null,
      }));
    }
    const buckets = new Map<string, { total: number; on: number; targetDays: number | null }>();
    items.forEach((p) => {
      if (p.status !== "selesai") return;
      const masuk = new Date(p.tanggal_masuk).getTime();
      const selesaiTs = new Date(p.updated_at).getTime();
      let onTime = false;
      let targetDays: number | null = null;
      if (p.tenggat) {
        onTime = selesaiTs <= new Date(p.tenggat).getTime();
        targetDays = Math.round((new Date(p.tenggat).getTime() - masuk) / 86400000);
      } else {
        const sla = slaMap.get(p.kategori);
        if (sla == null) return;
        const lamaHari = (selesaiTs - masuk) / 86400000;
        onTime = lamaHari <= sla;
        targetDays = sla;
      }
      const b = buckets.get(p.kategori) ?? { total: 0, on: 0, targetDays };
      b.total++;
      if (onTime) b.on++;
      if (b.targetDays == null) b.targetDays = targetDays;
      buckets.set(p.kategori, b);
    });
    return Array.from(buckets, ([nama, v]) => ({
      nama,
      persen: v.total ? Math.round((v.on / v.total) * 100) : 0,
      total: v.total,
      targetDays: v.targetDays,
    }))
      .sort((a, b) => b.total - a.total)
      .slice(0, 6);
  }, [items, slaMap, isSuperAdmin, summary]);

  const opdBacklog = useMemo(() => {
    if (!isSuperAdmin) return [];
    if (summary?.backlog?.length) {
      return summary.backlog.map((b) => ({
        nama: b.singkatan ?? b.nama ?? "—",
        baru: b.baru,
        diproses: b.diproses,
        total: b.baru + b.diproses,
      }));
    }
    const map = new Map<string, { baru: number; diproses: number }>();
    items.forEach((p) => {
      if (p.status !== "baru" && p.status !== "diproses") return;
      const o = opdList.find((x) => x.id === p.opd_id);
      const key = o?.singkatan ?? "—";
      const cur = map.get(key) ?? { baru: 0, diproses: 0 };
      cur[p.status]++;
      map.set(key, cur);
    });
    return Array.from(map, ([nama, v]) => ({ nama, ...v, total: v.baru + v.diproses }))
      .sort((a, b) => b.total - a.total)
      .slice(0, 6);
  }, [items, opdList, isSuperAdmin, summary]);

  const statusPie = useMemo(
    () =>
      [
        { name: "Baru", value: kpi.baru, fill: "oklch(0.55 0.16 258)" },
        { name: "Diproses", value: kpi.diproses, fill: "oklch(0.78 0.14 85)" },
        { name: "Selesai", value: kpi.selesai, fill: "oklch(0.62 0.14 155)" },
        { name: "Ditolak", value: kpi.ditolak, fill: "oklch(0.62 0.20 25)" },
      ].filter((s) => s.value > 0),
    [kpi],
  );

  return (
    <AdminShell
      opdAktifId={opdAktifId}
      onChangeOpd={isSuperAdmin ? setOpdAktifId : undefined}
      breadcrumb={[{ label: "Pelayanan Publik" }, { label: "Permohonan" }]}
    >
      <div className="mb-6">
        <h1 className="font-display text-2xl font-bold text-foreground md:text-3xl">
          Daftar Permohonan
        </h1>
        <p className="text-sm text-muted-foreground">
          Kelola permohonan layanan publik berdasarkan status dan kategori.
        </p>
      </div>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <StatCard label="Baru" value={kpi.baru} delta="Menunggu verifikasi" tone="accent" icon={Inbox} />
        <StatCard label="Diproses" value={kpi.diproses} delta="Sedang dikerjakan" tone="gold" icon={Loader2} />
        <StatCard label="Selesai" value={kpi.selesai} delta="Total" tone="success" icon={CheckCircle2} />
        <StatCard label="Ditolak" value={kpi.ditolak} delta="Berkas tidak lengkap" tone="destructive" icon={XCircle} />
      </div>

      <div className="mt-6 grid gap-4 lg:grid-cols-3">
        <div className="rounded-xl border border-border bg-card p-4 shadow-soft lg:col-span-2">
          <h2 className="font-display text-base font-semibold">Tren 14 hari terakhir</h2>
          <p className="text-xs text-muted-foreground">Permohonan masuk vs diselesaikan</p>
          <div className="mt-3 h-56 w-full">
            <Suspense fallback={<ChartFallback />}>
              <AdminTrendChart data={trend} />
            </Suspense>
          </div>
        </div>

        <div className="rounded-xl border border-border bg-card p-4 shadow-soft">
          <h2 className="font-display text-base font-semibold">Distribusi kategori</h2>
          <p className="text-xs text-muted-foreground">Top 8 layanan</p>
          <div className="mt-3 h-56 w-full">
            <Suspense fallback={<ChartFallback />}>
              <AdminKategoriChart data={distribusiKategori} />
            </Suspense>
          </div>
        </div>
      </div>

      {isSuperAdmin && (
        <>
          <div className="mt-8 mb-3">
            <h2 className="font-display text-base font-bold text-foreground">Insight Detail</h2>
            <p className="text-xs text-muted-foreground">
              Analisa permohonan, SLA, backlog & aktivitas sistem.
            </p>
          </div>
          <div className="mt-2 grid gap-4 lg:grid-cols-3">
            <div className="rounded-xl border border-border bg-card p-4 shadow-soft">
              <div className="flex items-center justify-between">
                <h2 className="font-display text-base font-semibold">Status Sistem</h2>
                <ShieldCheck className="h-4 w-4 text-success" />
              </div>
              <div className="mt-3 grid grid-cols-2 gap-3 text-sm">
                <div className="rounded-lg bg-surface p-3">
                  <div className="text-[10px] uppercase tracking-wide text-muted-foreground">Job Pending</div>
                  <div className="font-display text-xl font-bold">{sysStat?.jobs.pending ?? "—"}</div>
                </div>
                <div className="rounded-lg bg-surface p-3">
                  <div className="text-[10px] uppercase tracking-wide text-muted-foreground">Job Failed</div>
                  <div className={`font-display text-xl font-bold ${sysStat && sysStat.jobs.failed > 0 ? "text-destructive" : ""}`}>
                    {sysStat?.jobs.failed ?? "—"}
                  </div>
                </div>
                <div className="rounded-lg bg-surface p-3">
                  <div className="text-[10px] uppercase tracking-wide text-muted-foreground">Total User</div>
                  <div className="font-display text-xl font-bold">{sysStat?.users ?? "—"}</div>
                </div>
                <div className="rounded-lg bg-surface p-3">
                  <div className="text-[10px] uppercase tracking-wide text-muted-foreground">Berita / Layanan</div>
                  <div className="font-display text-xl font-bold">
                    {sysStat ? `${sysStat.berita}/${sysStat.layanan}` : "—"}
                  </div>
                </div>
              </div>
            </div>

            <div className="rounded-xl border border-border bg-card p-4 shadow-soft">
              <h2 className="font-display text-base font-semibold">Komposisi Status</h2>
              <p className="text-xs text-muted-foreground">Sebaran permohonan</p>
              <div className="mt-2 h-56 w-full">
                {statusPie.length === 0 ? (
                  <div className="grid h-full place-items-center text-xs text-muted-foreground">Belum ada data</div>
                ) : (
                  <Suspense fallback={<ChartFallback />}>
                    <AdminStatusPie data={statusPie} />
                  </Suspense>
                )}
              </div>
            </div>

            <div className="rounded-xl border border-border bg-card p-4 shadow-soft">
              <div className="flex items-center justify-between">
                <h2 className="font-display text-base font-semibold">Top OPD Backlog</h2>
                <Building2 className="h-4 w-4 text-muted-foreground" />
              </div>
              <ul className="mt-3 space-y-1.5">
                {opdBacklog.length === 0 && (
                  <li className="rounded-md bg-surface px-3 py-6 text-center text-xs text-muted-foreground">
                    Tidak ada backlog 🎉
                  </li>
                )}
                {opdBacklog.map((o) => (
                  <li key={o.nama} className="flex items-center justify-between rounded-md bg-surface px-3 py-2">
                    <div>
                      <div className="text-sm font-semibold">{o.nama}</div>
                      <div className="text-[10px] text-muted-foreground">
                        {o.baru} baru · {o.diproses} diproses
                      </div>
                    </div>
                    <span className="rounded-full bg-destructive/15 px-2 py-0.5 text-xs font-bold text-destructive">
                      {o.total}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          <div className="mt-4 rounded-xl border border-border bg-card p-4 shadow-soft">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="font-display text-base font-semibold">Kinerja SLA</h2>
                <p className="text-xs text-muted-foreground">% selesai dalam batas SLA per kategori</p>
              </div>
              <Clock className="h-4 w-4 text-muted-foreground" />
            </div>
            {slaPerformance.length === 0 ? (
              <div className="mt-3 rounded-md bg-surface px-3 py-8 text-center text-xs text-muted-foreground">
                Belum ada permohonan selesai untuk dihitung SLA-nya.
              </div>
            ) : (
              <ul className="mt-3 grid gap-2 md:grid-cols-2">
                {slaPerformance.map((s) => {
                  const tone = s.persen >= 80 ? "bg-success" : s.persen >= 50 ? "bg-gold" : "bg-destructive";
                  return (
                    <li key={s.nama} className="rounded-lg border border-border bg-surface p-3">
                      <div className="flex items-center justify-between">
                        <span className="text-sm font-semibold">{s.nama}</span>
                        <span className={`rounded-full px-2 py-0.5 text-xs font-bold ${s.persen >= 80 ? "bg-success/15 text-success" : s.persen >= 50 ? "bg-gold/20 text-gold-foreground" : "bg-destructive/15 text-destructive"}`}>
                          {s.persen}%
                        </span>
                      </div>
                      <div className="mt-2 h-1.5 w-full rounded-full bg-border">
                        <div className={`h-full rounded-full ${tone}`} style={{ width: `${s.persen}%` }} />
                      </div>
                      <div className="mt-1 text-[10px] text-muted-foreground">
                        {s.total} selesai{s.targetDays != null ? ` · target ${s.targetDays} hari` : ""}
                      </div>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>

          {sysStat && sysStat.jobs.failed > 0 && (
            <div className="mt-4 flex gap-3 rounded-xl border border-destructive/40 bg-destructive/10 p-4 text-sm">
              <AlertTriangle className="h-5 w-5 shrink-0 text-destructive" />
              <div className="flex-1">
                <div className="font-semibold text-foreground">Ada {sysStat.jobs.failed} job gagal</div>
                <p className="text-xs text-muted-foreground">Periksa dari halaman audit / backup.</p>
              </div>
              <Link to="/admin/audit" className="self-center rounded-md bg-destructive px-3 py-1.5 text-xs font-semibold text-destructive-foreground">
                Lihat
              </Link>
            </div>
          )}
        </>
      )}

      <section id="tabel" className="mt-6 rounded-xl border border-border bg-card shadow-soft">
        <div className="flex flex-col gap-3 border-b border-border p-4 md:flex-row md:items-center">
          <div className="flex items-center gap-2">
            <Filter className="h-4 w-4 text-muted-foreground" />
            <h2 className="font-display text-base font-semibold">Daftar Permohonan</h2>
            <span className="rounded-full bg-primary-soft px-2 py-0.5 text-xs font-medium text-primary">
              {filtered.length}
            </span>
          </div>
          <div className="md:ml-auto flex flex-col gap-2 sm:flex-row sm:items-center">
            <div className="relative">
              <Search className="absolute left-2 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder="Cari kode / judul…"
                className="h-9 w-full rounded-md border border-border bg-background pl-8 pr-3 text-sm sm:w-64"
              />
            </div>
            <select
              value={status}
              onChange={(e) => setStatus(e.target.value as "semua" | StatusPermohonan)}
              className="h-9 rounded-md border border-border bg-background px-2 text-sm"
            >
              {STATUS_OPTIONS.map((s) => (
                <option key={s} value={s}>
                  {s === "semua" ? "Semua status" : STATUS_LABEL[s]}
                </option>
              ))}
            </select>
            {opd && (
              <select
                value={kategori}
                onChange={(e) => setKategori(e.target.value)}
                className="h-9 rounded-md border border-border bg-background px-2 text-sm"
              >
                <option value="semua">Semua kategori</option>
                {opd.kategori.map((k) => (
                  <option key={k} value={k}>
                    {k}
                  </option>
                ))}
              </select>
            )}
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[640px] text-sm">
            <thead className="bg-surface text-left text-xs uppercase tracking-wide text-muted-foreground">
              <tr>
                <th className="px-4 py-3 font-medium">Kode</th>
                <th className="px-4 py-3 font-medium">Judul</th>
                <th className="px-4 py-3 font-medium">Kategori</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">Tanggal</th>
                <th className="px-4 py-3" />
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={6} className="px-4 py-12 text-center text-sm text-muted-foreground">
                    Memuat…
                  </td>
                </tr>
              )}
              {!loading && filtered.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-4 py-12 text-center text-sm text-muted-foreground">
                    Tidak ada permohonan.
                  </td>
                </tr>
              )}
              {filtered.map((p) => (
                <tr key={p.id} className="border-t border-border hover:bg-surface/60">
                  <td className="px-4 py-3 font-mono text-xs text-muted-foreground">{p.kode}</td>
                  <td className="px-4 py-3 font-medium text-foreground">{p.judul}</td>
                  <td className="px-4 py-3">{p.kategori}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex rounded-full border px-2 py-0.5 text-xs font-medium ${STATUS_TONE[p.status]}`}>
                      {STATUS_LABEL[p.status]}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-xs text-muted-foreground">
                    {fmtTanggal(p.tanggal_masuk)}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <div className="inline-flex items-center gap-2">
                      <Link
                        to="/permohonan/$id"
                        params={{ id: p.id }}
                        className="inline-flex items-center gap-1 text-xs font-medium text-primary hover:underline"
                      >
                        Detail <ArrowUpRight className="h-3 w-3" />
                      </Link>
                      {isSuperAdmin && (
                        <button
                          onClick={async () => {
                            if (!confirm(`Hapus permohonan ${p.kode}? Riwayat, rating & berkas terkait ikut terhapus.`)) return;
                            try {
                              await deletePermohonan({ data: { id: p.id } });
                              setItems((prev) => prev.filter((x) => x.id !== p.id));
                              toast.success("Permohonan dihapus");
                            } catch (e) {
                              toast.error((e as Error).message);
                            }
                          }}
                          className="inline-flex items-center gap-1 rounded-md border border-destructive/40 px-2 py-1 text-xs text-destructive hover:bg-destructive/10"
                          title="Hapus permohonan"
                        >
                          <Trash2 className="h-3 w-3" /> Hapus
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </AdminShell>
  );
}

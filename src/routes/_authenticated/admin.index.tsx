// Command Center — Super Admin. Widget permohonan (KPI, tren, insight, SLA,
// backlog, daftar) sudah dipindahkan ke halaman "Permohonan" (Pelayanan Publik).
import { useEffect, useState } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, FileText, ClipboardList, ShieldCheck, Users, Building2, MapPin } from "lucide-react";

import { AdminShell } from "@/components/admin/AdminShell";
import { AdminGuard } from "@/components/admin/AdminGuard";
import { SuperCommandCenter } from "@/components/admin/dashboard/SuperCommandCenter";
import { useAuth } from "@/lib/auth-context";
import { supabase } from "@/integrations/supabase/client";
import { dashboardSummaryQueryOptions } from "@/lib/queries.dashboard";

export const Route = createFileRoute("/_authenticated/admin/")({
  head: () => ({
    meta: [
      { title: "Pusat Kendali Super Admin — Kabupaten Buton Selatan" },
      { name: "description", content: "Ringkasan operasional, antrean kerja, dan lima ekosistem layanan Pemerintah Kabupaten Buton Selatan." },
      { property: "og:title", content: "Pusat Kendali Super Admin — Kabupaten Buton Selatan" },
      { property: "og:description", content: "Ringkasan operasional, antrean kerja, dan lima ekosistem layanan Pemerintah Kabupaten Buton Selatan." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: () => (
    <AdminGuard>
      <AdminDashboard />
    </AdminGuard>
  ),
});

function AdminDashboard() {
  const { isSuperAdmin, isAdminDesa, isVerified, profile, roles, user } = useAuth();
  const isAdminOpd = roles.includes("admin_opd");
  const needsVerification = isAdminOpd && !isSuperAdmin && !isVerified;
  const [opdAktifId, setOpdAktifId] = useState<string>("");
  const [opdSingkatan, setOpdSingkatan] = useState<string>("");

  useEffect(() => {
    if (!user || isSuperAdmin) return;
    supabase
      .from("profiles")
      .select("opd_id")
      .eq("id", user.id)
      .maybeSingle()
      .then(({ data }) => setOpdAktifId(data?.opd_id ?? ""));
  }, [user, isSuperAdmin]);

  useEffect(() => {
    if (!opdAktifId) {
      setOpdSingkatan("");
      return;
    }
    supabase
      .from("opd")
      .select("singkatan")
      .eq("id", opdAktifId)
      .maybeSingle()
      .then(({ data }) => setOpdSingkatan(data?.singkatan ?? ""));
  }, [opdAktifId]);

  const summaryQ = useQuery({
    ...dashboardSummaryQueryOptions(opdAktifId || null, 14),
    enabled: isSuperAdmin || !!opdAktifId,
  });

  if (needsVerification) {
    return (
      <AdminShell>
        <div className="mx-auto max-w-xl rounded-xl border border-amber-500/40 bg-amber-500/5 p-8 text-center shadow-soft">
          <AlertTriangle className="mx-auto h-10 w-10 text-amber-600 dark:text-amber-400" />
          <h1 className="mt-3 font-display text-xl font-bold">Akun Anda Menunggu Verifikasi</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Sebagai Admin OPD, akun Anda perlu diverifikasi terlebih dahulu oleh Super Admin sebelum
            dapat mengakses dashboard. Silakan hubungi Super Admin.
          </p>
          <p className="mt-3 text-xs text-muted-foreground">
            Email: <span className="font-medium text-foreground">{user?.email}</span>
          </p>
        </div>
      </AdminShell>
    );
  }

  return (
    <AdminShell opdAktifId={opdAktifId} onChangeOpd={isSuperAdmin ? setOpdAktifId : undefined}>
      <div className="mb-5 border-b border-border pb-5">
        <div className="text-[10px] font-bold uppercase text-primary">
          {opdSingkatan || (isAdminDesa && profile?.desa ? `Desa ${profile.desa}` : "Semua OPD")}
        </div>
        <h1 className="mt-1 max-w-3xl font-display text-2xl font-bold leading-tight text-foreground md:text-3xl">
          {isSuperAdmin ? "Pusat Kendali Super Admin" : "Dashboard Admin"}
        </h1>
        <p className="mt-1.5 max-w-3xl text-sm leading-relaxed text-muted-foreground">
          {isSuperAdmin
            ? "Pantau kondisi operasional, tindak lanjuti antrean, dan kelola lima ekosistem pemerintahan dalam satu layar."
            : "Ringkasan kerja & pintasan ke menu utama."}
        </p>
      </div>

      {isSuperAdmin ? (
        <SuperCommandCenter summary={summaryQ.data} />
      ) : (
        <NonSuperDashboard
          loading={summaryQ.isLoading}
          summary={summaryQ.data}
          isAdminOpd={isAdminOpd}
          isAdminDesa={isAdminDesa}
          opdAktifId={opdAktifId}
        />
      )}
    </AdminShell>
  );
}

type NonSuperProps = {
  loading: boolean;
  summary: import("@/lib/queries.dashboard").DashboardSummary | undefined;
  isAdminOpd: boolean;
  isAdminDesa: boolean;
  opdAktifId: string;
};


function NonSuperDashboard({ loading, summary, isAdminOpd, isAdminDesa, opdAktifId }: NonSuperProps) {
  const kpi = summary?.kpi;
  const kpiItems = [
    { label: "Baru", value: kpi?.baru ?? 0, tone: "bg-blue-500/10 text-blue-700 dark:text-blue-300" },
    { label: "Diproses", value: kpi?.diproses ?? 0, tone: "bg-amber-500/10 text-amber-700 dark:text-amber-300" },
    { label: "Selesai", value: kpi?.selesai ?? 0, tone: "bg-emerald-500/10 text-emerald-700 dark:text-emerald-300" },
    { label: "Ditolak", value: kpi?.ditolak ?? 0, tone: "bg-rose-500/10 text-rose-700 dark:text-rose-300" },
  ];

  const shortcuts: { to: string; label: string; desc: string; icon: React.ComponentType<{ className?: string }> }[] = [];
  if (isAdminOpd) {
    shortcuts.push(
      { to: "/admin/permohonan", label: "Permohonan", desc: "Kelola permohonan warga di OPD Anda.", icon: FileText },
      { to: "/admin/layanan", label: "Layanan Publik", desc: "Atur katalog layanan & persyaratan.", icon: ClipboardList },
      { to: "/admin/verifikasi", label: "Verifikasi Bukti", desc: "Pindai QR & verifikasi dokumen.", icon: ShieldCheck },
      { to: "/admin/asn", label: "ASN", desc: "Kelola pegawai, absensi, & izin.", icon: Users },
    );
  }
  if (isAdminDesa) {
    shortcuts.push(
      { to: "/admin/verifikasi", label: "Verifikasi Warga", desc: "Verifikasi identitas warga di desa Anda.", icon: ShieldCheck },
      { to: "/admin/laporan", label: "Laporan Warga", desc: "Kelola laporan/pengaduan warga.", icon: FileText },
      { to: "/admin/desa", label: "Data Desa", desc: "Perbarui profil & data desa.", icon: MapPin },
    );
  }
  if (shortcuts.length === 0) {
    shortcuts.push(
      { to: "/admin/permohonan", label: "Permohonan", desc: "Lihat daftar permohonan.", icon: FileText },
      { to: "/admin/layanan", label: "Layanan", desc: "Lihat katalog layanan.", icon: Building2 },
    );
  }

  return (
    <div className="space-y-6">
      {isAdminOpd && !opdAktifId && (
        <div className="rounded-xl border border-amber-500/40 bg-amber-500/5 p-4 text-sm text-amber-800 dark:text-amber-200">
          Profil OPD Anda belum terhubung. Hubungi Super Admin untuk menautkan akun Anda ke OPD.
        </div>
      )}

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {kpiItems.map((k) => (
          <div key={k.label} className="rounded-xl border border-border bg-card p-4 shadow-soft">
            <div className="text-xs font-medium uppercase tracking-wider text-muted-foreground">{k.label}</div>
            <div className={`mt-2 inline-flex min-w-[3rem] items-center justify-center rounded-md px-3 py-1 text-2xl font-bold ${k.tone}`}>
              {loading ? "…" : k.value}
            </div>
          </div>
        ))}
      </div>

      <div>
        <h2 className="mb-3 font-display text-lg font-semibold">Pintasan</h2>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {shortcuts.map((s) => (
            <Link
              key={s.to}
              to={s.to}
              className="group flex items-start gap-3 rounded-xl border border-border bg-card p-4 shadow-soft transition hover:border-primary/50 hover:bg-primary-soft"
            >
              <div className="grid h-10 w-10 place-items-center rounded-lg bg-primary/10 text-primary">
                <s.icon className="h-5 w-5" />
              </div>
              <div className="min-w-0">
                <div className="font-semibold text-foreground group-hover:text-primary">{s.label}</div>
                <div className="text-xs text-muted-foreground">{s.desc}</div>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}


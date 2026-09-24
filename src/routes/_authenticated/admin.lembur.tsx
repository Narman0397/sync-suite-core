// Admin OPD / Super admin: persetujuan pengajuan lembur (SPL).
import { useCallback, useEffect, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { toast } from "sonner";
import { AdminShell } from "@/components/admin/AdminShell";
import { AdminGuard } from "@/components/admin/AdminGuard";
import { listOvertime, decideOvertime } from "@/lib/overtime.functions";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

type Row = {
  id: string;
  user_id: string;
  tanggal: string;
  jam_mulai: string;
  jam_selesai: string;
  alasan: string;
  status: string;
  catatan_approval: string | null;
  created_at: string;
  profile: { nama_lengkap: string | null } | null;
};

export const Route = createFileRoute("/_authenticated/admin/lembur")({
  head: () => ({
    meta: [{ title: "Persetujuan Lembur ASN" }, { name: "robots", content: "noindex" }],
  }),
  component: () => (
    <AdminGuard>
      <AdminShell breadcrumb={[{ label: "ASN" }, { label: "Persetujuan Lembur" }]}>
        <Page />
      </AdminShell>
    </AdminGuard>
  ),
});

function Page() {
  const fnList = useServerFn(listOvertime);
  const fnDecide = useServerFn(decideOvertime);
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await fnList({ data: { scope: "admin" } });
      setRows((r as unknown as { rows: Row[] }).rows ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Gagal memuat data lembur");
    } finally {
      setLoading(false);
    }
  }, [fnList]);

  useEffect(() => {
    void load();
  }, [load]);

  async function decide(id: string, decision: "approved" | "rejected") {
    setBusy(id);
    try {
      await fnDecide({ data: { id, decision } });
      toast.success(decision === "approved" ? "Lembur disetujui" : "Lembur ditolak");
      await load();
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Gagal memproses");
    } finally {
      setBusy(null);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Pengajuan Lembur</CardTitle>
      </CardHeader>
      <CardContent>
        {loading && <div className="py-8 text-center text-sm text-muted-foreground">Memuat…</div>}
        {error && <div className="py-8 text-center text-sm text-destructive">{error}</div>}
        {!loading && !error && rows.length === 0 && (
          <div className="py-10 text-center text-sm text-muted-foreground">
            Belum ada pengajuan lembur.
          </div>
        )}
        {rows.length > 0 && (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b text-left">
                  <th className="py-2">Pegawai</th>
                  <th>Tanggal</th>
                  <th>Jam</th>
                  <th>Alasan</th>
                  <th>Status</th>
                  <th className="text-right">Tindakan</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((r) => (
                  <tr key={r.id} className="border-b align-top">
                    <td className="py-2">{r.profile?.nama_lengkap ?? "—"}</td>
                    <td className="tabular-nums">{r.tanggal}</td>
                    <td className="tabular-nums">
                      {r.jam_mulai}–{r.jam_selesai}
                    </td>
                    <td className="max-w-xs">{r.alasan}</td>
                    <td className="capitalize">{r.status}</td>
                    <td className="text-right">
                      {r.status === "pending" ? (
                        <span className="inline-flex gap-2">
                          <Button
                            size="sm"
                            disabled={busy === r.id}
                            onClick={() => decide(r.id, "approved")}
                          >
                            Setujui
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            disabled={busy === r.id}
                            onClick={() => decide(r.id, "rejected")}
                          >
                            Tolak
                          </Button>
                        </span>
                      ) : (
                        <span className="text-xs text-muted-foreground">
                          {r.catatan_approval ?? "—"}
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

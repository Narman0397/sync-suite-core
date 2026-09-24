// Admin Pengumuman — CRUD + target penerima ala Form Builder.
import { useEffect, useMemo, useRef, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import { toast } from "sonner";
import { Plus, Pencil, Trash2, X, Megaphone, Send, Search, Save } from "lucide-react";
import { AdminShell } from "@/components/admin/AdminShell";
import { AdminGuard } from "@/components/admin/AdminGuard";
import {
  listAnnouncements,
  getAnnouncement,
  upsertAnnouncement,
  publishAnnouncement,
  deleteAnnouncement,
  previewRecipientCount,
} from "@/lib/announcements.functions";
import { listOpdsForTarget, searchProfilesForTarget } from "@/lib/forms-options.functions";
import {
  ROLES,
  ROLE_LABEL,
  ASN_TYPES,
  ASN_TYPE_LABEL,
  POSITIONS,
  POSITION_LABEL,
} from "@/features/rbac/constants";

export const Route = createFileRoute("/_authenticated/admin/pengumuman")({
  head: () => ({
    meta: [{ title: "Pengumuman — Admin" }, { name: "robots", content: "noindex" }],
  }),
  component: () => (
    <AdminGuard>
      <Page />
    </AdminGuard>
  ),
});

type Target = { target_type: string; target_value: string };
type Opd = { id: string; nama: string; singkatan: string | null };
type ProfileHit = {
  id: string;
  nama_lengkap: string;
  nip: string | null;
  opd: { nama: string | null; singkatan: string | null } | null;
};

const PRIORITAS_LABEL: Record<string, string> = {
  info: "Info",
  penting: "Penting",
  urgent: "Urgent",
};

const TYPE_LABEL: Record<string, string> = {
  role: "Role",
  opd: "OPD",
  asn_type: "Jenis ASN",
  position: "Jabatan Sistem",
  individu: "Individu (ASN)",
};
const TYPE_OPTIONS = ["role", "opd", "asn_type", "position", "individu"] as const;

function Page() {
  const qc = useQueryClient();
  const listFn = useServerFn(listAnnouncements);
  const list = useQuery({
    queryKey: ["announcements"],
    queryFn: () => listFn({ data: { page: 0, pageSize: 50, status: "all" } }),
  });
  const [editId, setEditId] = useState<string | "new" | null>(null);
  const delFn = useServerFn(deleteAnnouncement);
  const pubFn = useServerFn(publishAnnouncement);

  return (
    <AdminShell breadcrumb={[{ label: "Konten & Branding" }, { label: "Pengumuman" }]}>
      <div className="mb-4 flex items-center justify-between">
        <h1 className="font-display text-2xl font-bold flex items-center gap-2">
          <Megaphone className="h-6 w-6 text-primary" /> Pengumuman
        </h1>
        <button
          onClick={() => setEditId("new")}
          className="inline-flex items-center gap-1 rounded-md bg-primary px-3 py-2 text-sm font-semibold text-primary-foreground"
        >
          <Plus className="h-4 w-4" /> Buat Pengumuman
        </button>
      </div>

      <div className="rounded-xl border border-border bg-card">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-left text-xs uppercase text-muted-foreground">
            <tr>
              <th className="px-3 py-2">Judul</th>
              <th className="px-3 py-2">Prioritas</th>
              <th className="px-3 py-2">Status</th>
              <th className="px-3 py-2">Diperbarui</th>
              <th className="px-3 py-2 text-right">Aksi</th>
            </tr>
          </thead>
          <tbody>
            {list.isLoading && (
              <tr>
                <td colSpan={5} className="px-3 py-6 text-center text-muted-foreground">
                  Memuat…
                </td>
              </tr>
            )}
            {list.data?.rows.length === 0 && (
              <tr>
                <td colSpan={5} className="px-3 py-6 text-center text-muted-foreground">
                  Belum ada pengumuman.
                </td>
              </tr>
            )}
            {list.data?.rows.map((r: any) => (
              <tr key={r.id} className="border-b border-border last:border-0">
                <td className="px-3 py-2 font-medium">{r.judul}</td>
                <td className="px-3 py-2">
                  <span className="rounded-full border border-border px-2 py-0.5 text-xs">
                    {PRIORITAS_LABEL[r.prioritas] ?? r.prioritas}
                  </span>
                </td>
                <td className="px-3 py-2">
                  <span
                    className={
                      "rounded-full px-2 py-0.5 text-xs " +
                      (r.status === "published"
                        ? "bg-green-500/10 text-green-700 dark:text-green-400"
                        : "bg-muted text-muted-foreground")
                    }
                  >
                    {r.status}
                  </span>
                </td>
                <td className="px-3 py-2 text-xs text-muted-foreground">
                  {new Date(r.updated_at).toLocaleString("id-ID")}
                </td>
                <td className="px-3 py-2 text-right">
                  <div className="inline-flex gap-1">
                    {r.status === "draft" && (
                      <button
                        onClick={async () => {
                          if (!confirm("Publikasikan pengumuman ini? Notifikasi akan dikirim.")) return;
                          try {
                            const res = (await pubFn({ data: { id: r.id } })) as {
                              recipients: number;
                            };
                            toast.success(`Terkirim ke ${res.recipients} penerima`);
                            qc.invalidateQueries({ queryKey: ["announcements"] });
                          } catch (e) {
                            toast.error(e instanceof Error ? e.message : "Gagal publish");
                          }
                        }}
                        className="inline-flex h-8 items-center gap-1 rounded-md bg-primary/90 px-2 text-xs font-semibold text-primary-foreground"
                      >
                        <Send className="h-3 w-3" /> Publish
                      </button>
                    )}
                    <button
                      onClick={() => setEditId(r.id)}
                      className="inline-flex h-8 w-8 items-center justify-center rounded-md border border-border"
                      title="Edit"
                    >
                      <Pencil className="h-3.5 w-3.5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (!confirm("Hapus pengumuman ini?")) return;
                        try {
                          await delFn({ data: { id: r.id } });
                          toast.success("Terhapus");
                          qc.invalidateQueries({ queryKey: ["announcements"] });
                        } catch (e) {
                          toast.error(e instanceof Error ? e.message : "Gagal hapus");
                        }
                      }}
                      className="inline-flex h-8 w-8 items-center justify-center rounded-md border border-border text-destructive"
                      title="Hapus"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {editId && (
        <Editor
          id={editId === "new" ? null : editId}
          onClose={() => setEditId(null)}
          onSaved={() => qc.invalidateQueries({ queryKey: ["announcements"] })}
        />
      )}
    </AdminShell>
  );
}

function Editor({
  id,
  onClose,
  onSaved,
}: {
  id: string | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const getFn = useServerFn(getAnnouncement);
  const upsertFn = useServerFn(upsertAnnouncement);
  const pubFn = useServerFn(publishAnnouncement);
  const previewFn = useServerFn(previewRecipientCount);

  const [judul, setJudul] = useState("");
  const [isi, setIsi] = useState("");
  const [prioritas, setPrioritas] = useState<"info" | "penting" | "urgent">("info");
  const [link, setLink] = useState("");
  const [opdPemilikId, setOpdPemilikId] = useState<string | null>(null);
  const [targets, setTargets] = useState<Target[]>([]);
  const [tab, setTab] = useState<"detail" | "target">("detail");
  const [busy, setBusy] = useState(false);
  const [recipientPreview, setRecipientPreview] = useState<number | null>(null);
  const [opds, setOpds] = useState<Opd[]>([]);
  const [userLabels, setUserLabels] = useState<Record<string, string>>({});

  useEffect(() => {
    (async () => {
      const r = (await listOpdsForTarget()) as unknown as { rows: Opd[] };
      setOpds(r.rows);
    })().catch(() => undefined);
  }, []);

  useEffect(() => {
    if (!id) return;
    (async () => {
      const r = (await getFn({ data: { id } })) as {
        row: any;
        targets: Array<{ target_type: string; target_value: string }>;
      };
      setJudul(r.row.judul);
      setIsi(r.row.isi ?? "");
      setPrioritas(r.row.prioritas);
      setLink(r.row.link ?? "");
      setOpdPemilikId(r.row.opd_pemilik_id ?? null);
      setTargets(r.targets.map((t) => ({ target_type: t.target_type, target_value: t.target_value })));
    })().catch((e) => toast.error(e instanceof Error ? e.message : "Gagal memuat"));
  }, [id, getFn]);

  async function refreshPreview(next: Target[], opd: string | null) {
    try {
      const r = (await previewFn({
        data: { opd_pemilik_id: opd, targets: next },
      })) as { count: number };
      setRecipientPreview(r.count);
    } catch {
      setRecipientPreview(null);
    }
  }

  async function save(): Promise<string | null> {
    if (judul.trim().length < 3) {
      toast.error("Judul minimal 3 karakter");
      return null;
    }
    setBusy(true);
    try {
      const r = (await upsertFn({
        data: {
          id: id ?? undefined,
          judul,
          isi,
          prioritas,
          link: link.trim() || null,
          opd_pemilik_id: opdPemilikId,
          targets: targets.filter((t) => t.target_value),
        },
      })) as { id: string };
      toast.success("Tersimpan");
      onSaved();
      return r.id;
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Gagal simpan");
      return null;
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-background/80 p-4 backdrop-blur">
      <div className="w-full max-w-3xl rounded-xl border border-border bg-card shadow-elevated">
        <div className="flex items-center justify-between border-b border-border px-4 py-3">
          <h2 className="text-lg font-semibold">
            {id ? "Edit Pengumuman" : "Buat Pengumuman"}
          </h2>
          <button
            onClick={onClose}
            className="inline-flex h-8 w-8 items-center justify-center rounded-md border border-border"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="flex gap-1 border-b border-border px-4 pt-2">
          {(["detail", "target"] as const).map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={
                "border-b-2 px-3 py-2 text-sm font-medium " +
                (tab === t
                  ? "border-primary text-foreground"
                  : "border-transparent text-muted-foreground")
              }
            >
              {t === "detail" ? "Detail" : "Target Penerima"}
            </button>
          ))}
        </div>

        <div className="space-y-3 px-4 py-4">
          {tab === "detail" && (
            <>
              <Field label="Judul">
                <input
                  className="input"
                  value={judul}
                  onChange={(e) => setJudul(e.target.value)}
                  maxLength={200}
                />
              </Field>
              <Field label="Isi">
                <textarea
                  className="input min-h-[140px]"
                  value={isi}
                  onChange={(e) => setIsi(e.target.value)}
                  maxLength={5000}
                />
              </Field>
              <div className="grid grid-cols-2 gap-3">
                <Field label="Prioritas">
                  <select
                    className="input"
                    value={prioritas}
                    onChange={(e) => setPrioritas(e.target.value as "info" | "penting" | "urgent")}
                  >
                    <option value="info">Info</option>
                    <option value="penting">Penting</option>
                    <option value="urgent">Urgent</option>
                  </select>
                </Field>
                <Field label="Link (opsional)">
                  <input
                    className="input"
                    value={link}
                    onChange={(e) => setLink(e.target.value)}
                    placeholder="/berita atau https://…"
                  />
                </Field>
              </div>
              <Field label="OPD Pemilik (opsional)">
                <select
                  className="input"
                  value={opdPemilikId ?? ""}
                  onChange={(e) => {
                    const v = e.target.value || null;
                    setOpdPemilikId(v);
                    refreshPreview(targets, v);
                  }}
                >
                  <option value="">— tanpa OPD (lintas-OPD) —</option>
                  {opds.map((o) => (
                    <option key={o.id} value={o.id}>
                      {o.singkatan ? `${o.singkatan} — ` : ""}
                      {o.nama}
                    </option>
                  ))}
                </select>
              </Field>
            </>
          )}

          {tab === "target" && (
            <div className="space-y-3">
              <p className="text-xs text-muted-foreground">
                Tentukan siapa yang menerima notifikasi. Jika kosong, default = semua user di OPD
                pemilik (atau semua ASN jika lintas-OPD).
              </p>

              {targets.map((t, i) => (
                <div key={i} className="grid grid-cols-12 gap-2 items-start">
                  <select
                    value={t.target_type}
                    onChange={(e) => {
                      const arr = [...targets];
                      const nt = e.target.value;
                      const defaultVal =
                        nt === "role"
                          ? ROLES.asn
                          : nt === "asn_type"
                            ? ASN_TYPES.pns
                            : nt === "position"
                              ? POSITIONS.staff
                              : "";
                      arr[i] = { target_type: nt, target_value: defaultVal };
                      setTargets(arr);
                      refreshPreview(arr, opdPemilikId);
                    }}
                    className="col-span-4 rounded-md border border-border bg-background px-2 py-1.5 text-sm"
                  >
                    {TYPE_OPTIONS.map((tp) => (
                      <option key={tp} value={tp}>
                        {TYPE_LABEL[tp]}
                      </option>
                    ))}
                  </select>

                  <div className="col-span-7">
                    {t.target_type === "opd" && (
                      <select
                        value={t.target_value}
                        onChange={(e) => {
                          const arr = [...targets];
                          arr[i] = { ...arr[i], target_value: e.target.value };
                          setTargets(arr);
                          refreshPreview(arr, opdPemilikId);
                        }}
                        className="w-full rounded-md border border-border bg-background px-2 py-1.5 text-sm"
                      >
                        <option value="">-- pilih OPD --</option>
                        {opds.map((o) => (
                          <option key={o.id} value={o.id}>
                            {o.singkatan ? `${o.singkatan} — ` : ""}
                            {o.nama}
                          </option>
                        ))}
                      </select>
                    )}
                    {t.target_type === "role" && (
                      <select
                        value={t.target_value}
                        onChange={(e) => {
                          const arr = [...targets];
                          arr[i] = { ...arr[i], target_value: e.target.value };
                          setTargets(arr);
                          refreshPreview(arr, opdPemilikId);
                        }}
                        className="w-full rounded-md border border-border bg-background px-2 py-1.5 text-sm"
                      >
                        {Object.values(ROLES).map((r) => (
                          <option key={r} value={r}>
                            {ROLE_LABEL[r as keyof typeof ROLE_LABEL]}
                          </option>
                        ))}
                      </select>
                    )}
                    {t.target_type === "asn_type" && (
                      <select
                        value={t.target_value}
                        onChange={(e) => {
                          const arr = [...targets];
                          arr[i] = { ...arr[i], target_value: e.target.value };
                          setTargets(arr);
                          refreshPreview(arr, opdPemilikId);
                        }}
                        className="w-full rounded-md border border-border bg-background px-2 py-1.5 text-sm"
                      >
                        {Object.values(ASN_TYPES).map((v) => (
                          <option key={v} value={v}>
                            {ASN_TYPE_LABEL[v as keyof typeof ASN_TYPE_LABEL]}
                          </option>
                        ))}
                      </select>
                    )}
                    {t.target_type === "position" && (
                      <select
                        value={t.target_value}
                        onChange={(e) => {
                          const arr = [...targets];
                          arr[i] = { ...arr[i], target_value: e.target.value };
                          setTargets(arr);
                          refreshPreview(arr, opdPemilikId);
                        }}
                        className="w-full rounded-md border border-border bg-background px-2 py-1.5 text-sm"
                      >
                        {Object.values(POSITIONS).map((v) => (
                          <option key={v} value={v}>
                            {POSITION_LABEL[v as keyof typeof POSITION_LABEL]}
                          </option>
                        ))}
                      </select>
                    )}
                    {t.target_type === "individu" && (
                      <UserPicker
                        value={t.target_value}
                        label={userLabels[t.target_value]}
                        onPick={(u) => {
                          setUserLabels((prev) => ({
                            ...prev,
                            [u.id]: `${u.nama_lengkap}${u.nip ? ` (${u.nip})` : ""}${u.opd?.singkatan ? ` — ${u.opd.singkatan}` : ""}`,
                          }));
                          const arr = [...targets];
                          arr[i] = { ...arr[i], target_value: u.id };
                          setTargets(arr);
                          refreshPreview(arr, opdPemilikId);
                        }}
                      />
                    )}
                  </div>

                  <button
                    onClick={() => {
                      const arr = targets.filter((_, k) => k !== i);
                      setTargets(arr);
                      refreshPreview(arr, opdPemilikId);
                    }}
                    className="col-span-1 inline-flex h-9 items-center justify-center rounded-md border border-border text-destructive"
                    title="Hapus baris"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              ))}

              <div className="flex items-center gap-3">
                <button
                  onClick={() => {
                    const arr = [
                      ...targets,
                      { target_type: "role", target_value: ROLES.asn },
                    ];
                    setTargets(arr);
                    refreshPreview(arr, opdPemilikId);
                  }}
                  className="inline-flex items-center gap-1 rounded-md border border-border px-3 py-2 text-sm"
                >
                  <Plus className="h-4 w-4" /> Tambah Target
                </button>
                <button
                  onClick={() => refreshPreview(targets, opdPemilikId)}
                  className="inline-flex items-center gap-1 rounded-md border border-border px-3 py-2 text-sm"
                >
                  Hitung Penerima
                </button>
                {recipientPreview !== null && (
                  <span className="text-sm text-muted-foreground">
                    Estimasi penerima: <strong>{recipientPreview}</strong>
                  </span>
                )}
              </div>
            </div>
          )}
        </div>

        <div className="flex items-center justify-end gap-2 border-t border-border px-4 py-3">
          <button
            onClick={onClose}
            className="rounded-md border border-border px-3 py-2 text-sm"
          >
            Batal
          </button>
          <button
            onClick={save}
            disabled={busy}
            className="inline-flex items-center gap-1 rounded-md border border-border px-3 py-2 text-sm"
          >
            <Save className="h-4 w-4" /> Simpan Draft
          </button>
          <button
            disabled={busy}
            onClick={async () => {
              const savedId = await save();
              if (!savedId) return;
              if (!confirm("Publikasikan sekarang? Notifikasi akan dikirim ke penerima.")) return;
              try {
                const res = (await pubFn({ data: { id: savedId } })) as { recipients: number };
                toast.success(`Terkirim ke ${res.recipients} penerima`);
                onSaved();
                onClose();
              } catch (e) {
                toast.error(e instanceof Error ? e.message : "Gagal publish");
              }
            }}
            className="inline-flex items-center gap-1 rounded-md bg-primary px-3 py-2 text-sm font-semibold text-primary-foreground"
          >
            <Send className="h-4 w-4" /> Simpan & Publikasikan
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs text-muted-foreground">{label}</span>
      {children}
    </label>
  );
}

function UserPicker({
  value,
  label,
  onPick,
}: {
  value: string;
  label?: string;
  onPick: (u: ProfileHit) => void;
}) {
  const [q, setQ] = useState("");
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [hits, setHits] = useState<ProfileHit[]>([]);
  const tRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const searchFn = useServerFn(searchProfilesForTarget);
  const display = useMemo(
    () => label ?? (value ? `User ${value.slice(0, 8)}…` : ""),
    [label, value],
  );

  useEffect(() => {
    if (!open) return;
    if (q.trim().length < 2) {
      setHits([]);
      return;
    }
    if (tRef.current) clearTimeout(tRef.current);
    tRef.current = setTimeout(async () => {
      setBusy(true);
      try {
        const r = (await searchFn({ data: { q: q.trim() } })) as unknown as { rows: ProfileHit[] };
        setHits(r.rows);
      } catch {
        setHits([]);
      } finally {
        setBusy(false);
      }
    }, 250);
    return () => {
      if (tRef.current) clearTimeout(tRef.current);
    };
  }, [q, open, searchFn]);

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="flex w-full items-center gap-2 rounded-md border border-border bg-background px-2 py-1.5 text-left text-sm"
      >
        <Search className="h-3.5 w-3.5 text-muted-foreground" />
        <span className={display ? "" : "text-muted-foreground"}>
          {display || "Cari ASN (nama / NIP)…"}
        </span>
      </button>
      {open && (
        <div className="absolute z-30 mt-1 w-full overflow-hidden rounded-md border border-border bg-popover shadow-elevated">
          <input
            autoFocus
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Ketik nama atau NIP…"
            className="w-full border-b border-border bg-background px-2 py-1.5 text-sm outline-none"
          />
          <div className="max-h-56 overflow-y-auto">
            {busy && <div className="px-3 py-2 text-xs text-muted-foreground">Mencari…</div>}
            {!busy && q.trim().length < 2 && (
              <div className="px-3 py-2 text-xs text-muted-foreground">
                Ketik minimal 2 karakter
              </div>
            )}
            {!busy && q.trim().length >= 2 && hits.length === 0 && (
              <div className="px-3 py-2 text-xs text-muted-foreground">Tidak ada hasil</div>
            )}
            {hits.map((u) => (
              <button
                key={u.id}
                type="button"
                onClick={() => {
                  onPick(u);
                  setOpen(false);
                  setQ("");
                }}
                className="block w-full px-3 py-2 text-left text-sm hover:bg-muted"
              >
                <div className="font-medium">{u.nama_lengkap}</div>
                <div className="text-xs text-muted-foreground">
                  {u.nip ?? "—"} {u.opd?.singkatan ? `• ${u.opd.singkatan}` : ""}
                </div>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

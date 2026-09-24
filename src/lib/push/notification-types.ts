// Katalog seluruh tipe notifikasi yang bisa diproduksi aplikasi.
// Dipakai oleh harness E2E untuk memicu 1 push per tipe & memverifikasi
// bahwa web-push benar-benar terkirim + ter-decrypt di sink test.
export type NotifSpec = {
  tipe: string;
  judul: string;
  body: string;
  link: string;
};

export const ALL_NOTIFICATION_TYPES: NotifSpec[] = [
  { tipe: "form.assigned", judul: "Tes: Form ditugaskan", body: "assigned", link: "/asn/tugas" },
  { tipe: "form.submitted", judul: "Tes: Form disubmit", body: "submitted", link: "/admin/permohonan" },
  { tipe: "form.approved", judul: "Tes: Form disetujui", body: "approved", link: "/permohonan" },
  { tipe: "form.rejected", judul: "Tes: Form ditolak", body: "rejected", link: "/permohonan" },
  { tipe: "form.revision_required", judul: "Tes: Revisi form", body: "revision", link: "/permohonan" },
  { tipe: "workflow.task.new", judul: "Tes: Task workflow baru", body: "task new", link: "/asn/tugas" },
  { tipe: "workflow.task.delegated", judul: "Tes: Task didelegasikan", body: "delegated", link: "/asn/tugas" },
  { tipe: "workflow.progress", judul: "Tes: Progress workflow", body: "progress", link: "/permohonan" },
  { tipe: "workflow.complete", judul: "Tes: Workflow selesai", body: "complete", link: "/permohonan" },
  { tipe: "sla.reminder", judul: "Tes: Pengingat SLA", body: "reminder", link: "/asn/tugas" },
  { tipe: "sla.escalated", judul: "Tes: Eskalasi SLA", body: "escalated", link: "/admin/permohonan" },
  { tipe: "assignment.reminder", judul: "Tes: Pengingat penugasan", body: "assign reminder", link: "/asn/tugas" },
  { tipe: "form.deadline", judul: "Tes: Deadline form", body: "deadline", link: "/asn/tugas" },
  { tipe: "aset.warranty", judul: "Tes: Garansi aset", body: "warranty", link: "/asn/aset" },
  { tipe: "announcement.broadcast", judul: "Tes: Pengumuman", body: "broadcast", link: "/pengumuman" },
  { tipe: "lapor.new", judul: "Tes: Laporan baru", body: "lapor new", link: "/admin/laporan" },
  { tipe: "lapor.status_changed", judul: "Tes: Status laporan", body: "lapor status", link: "/lapor/saya" },
  { tipe: "disposisi.new", judul: "Tes: Disposisi baru", body: "dispo new", link: "/admin/layanan/disposisi-inbox" },
  { tipe: "disposisi.acted", judul: "Tes: Disposisi ditindaklanjuti", body: "dispo acted", link: "/admin/layanan/disposisi-inbox" },
  { tipe: "izin.new", judul: "Tes: Pengajuan izin", body: "izin new", link: "/admin/izin" },
  { tipe: "izin.decided", judul: "Tes: Keputusan izin", body: "izin decided", link: "/asn/izin" },
  { tipe: "lembur.new", judul: "Tes: Pengajuan lembur", body: "lembur new", link: "/admin/lembur" },
  { tipe: "lembur.decided", judul: "Tes: Keputusan lembur", body: "lembur decided", link: "/asn/lembur" },
  { tipe: "mutasi.new", judul: "Tes: Mutasi aset", body: "mutasi new", link: "/admin/aset-extra" },
  { tipe: "mutasi.decided", judul: "Tes: Keputusan mutasi", body: "mutasi decided", link: "/asn/aset" },
  { tipe: "bast.issued", judul: "Tes: BAST diterbitkan", body: "bast issued", link: "/admin/aset/bast" },
  { tipe: "bast.approved", judul: "Tes: BAST disetujui", body: "bast approved", link: "/admin/aset/bast" },
  { tipe: "dataset.reviewed", judul: "Tes: Review dataset", body: "dataset reviewed", link: "/data" },
  { tipe: "verifikasi.approved", judul: "Tes: Akun disetujui", body: "verif approved", link: "/akun" },
  { tipe: "verifikasi.rejected", judul: "Tes: Akun ditolak", body: "verif rejected", link: "/akun" },
  { tipe: "ikm.new", judul: "Tes: IKM baru", body: "ikm new", link: "/admin/ikm" },
];

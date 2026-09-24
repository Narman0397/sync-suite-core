# FK Audit Report — PostgREST Relationship Integrity

> Mode: **READ ONLY**. Tidak ada kode / migration yang diubah. Semua temuan berasal dari `src/**` dan `information_schema` database berjalan (dev).

---

## 1. Executive Summary

| Metrik | Nilai |
|---|---|
| Total tabel di `public` | **124** |
| Total FK **terpakai** di source code (unik: `<table>!<column>`) | **22** |
| Total FK yang **benar-benar ada** di database (`information_schema.table_constraints`) | **5** |
| FK cocok (source ↔ DB) | **3** (`opd!opd_id` → `absensi_asn/bukti_dokumen/bukti_template_override`, `forms!form_id`) |
| FK **missing** yang dipakai query PostgREST | **≥ 19 pola relasi unik**, muncul di **50+ query** di 25+ file |
| FK yang di-*declare* di migration `supabase/migrations/*.sql` | **~200** (355 kemunculan `REFERENCES`, 156 `FOREIGN KEY`) |
| Selisih migration vs realita DB | **~195 FK gagal / tidak terpasang** |
| Severity Critical | **19 pola relasi** memblokir menu produksi |
| RLS aktif | 58 / 124 tabel |

**Root cause satu kalimat:** runner migrasi yang dipakai saat sinkronisasi ZIP menjalankan file per file dengan flag "skip benign" dan multi-pass; **hampir semua constraint FK inline (`REFERENCES ...`) dan `ADD CONSTRAINT ... FOREIGN KEY` gagal karena tabel target belum ada saat pass tersebut, lalu file ditandai `applied` pada pass berikutnya tanpa mengulang bagian FK**. Hasil: kolom (`opd_id`, `pemohon_id`, dst.) ada, tetapi metadata FK tidak dibuat sehingga PostgREST tidak bisa meng-embed relasi → error `couldn't find relationship between permohonan and opd in the schema cache`.

---

## 2. FK yang Benar-benar Ada di Database

Query: `information_schema.table_constraints` + `key_column_usage` + `constraint_column_usage`, `constraint_type='FOREIGN KEY'`, schema `public`.

| Constraint | Source | Target |
|---|---|---|
| `absensi_asn_opd_id_fkey` | `public.absensi_asn.opd_id` | `public.opd.id` |
| `bukti_dokumen_opd_id_fkey` | `public.bukti_dokumen.opd_id` | `public.opd.id` |
| `bukti_template_override_opd_id_fkey` | `public.bukti_template_override.opd_id` | `public.opd.id` |
| `form_submissions_form_id_fkey` | `public.form_submissions.form_id` | `public.forms.id` |
| `layanan_publik_document_template_id_fkey` | `public.layanan_publik.document_template_id` | `public.document_templates.id` |

**Total: 5.** Itu saja.

---

## 3. FK yang Dipakai Source Code (Unik)

Pola PostgREST `alias:table!fk_hint(...)` diekstrak dari `src/**/*.ts`:

| # | Hint di query | Kolom sumber (yang di-hint) | Target logis | Status DB |
|---|---|---|---|---|
| 1 | `opd!opd_id` | `<many>.opd_id` | `opd.id` | ✅ hanya untuk 3 tabel (`absensi_asn`, `bukti_dokumen`, `bukti_template_override`); ❌ untuk sisanya (lihat §5) |
| 2 | `opd!opd_pemilik_id` | `dataset_template.opd_pemilik_id`, `forms.opd_pemilik_id` | `opd.id` | ❌ MISSING |
| 3 | `opd!dari_opd` | `aset_mutasi.dari_opd` | `opd.id` | ❌ MISSING |
| 4 | `opd!ke_opd` | `aset_mutasi.ke_opd` | `opd.id` | ❌ MISSING |
| 5 | `profiles!user_id` | `overtime_requests.user_id`, `leave_balances.user_id`, `absensi_asn.user_id`, `form_submissions.user_id`, dsb. | `profiles.id` | ❌ MISSING |
| 6 | `profiles!pemegang_user_id` | `aset.pemegang_user_id` | `profiles.id` | ❌ MISSING |
| 7 | `profiles!oleh` | `aset_riwayat.oleh`, `form_submission_comment.oleh` | `profiles.id` | ❌ MISSING |
| 8 | `profiles!oleh_user_id` | `dataset_submission.oleh_user_id` | `profiles.id` | ❌ MISSING |
| 9 | `profiles!created_by` | `form_submission_versions.created_by` | `profiles.id` | ❌ MISSING |
| 10 | `profiles!pemberi_user` | `aset_bast.pemberi_user` | `profiles.id` | ❌ MISSING |
| 11 | `profiles!penerima_user` | `aset_bast.penerima_user` | `profiles.id` | ❌ MISSING |
| 12 | `profiles!dari_user` | `aset_mutasi.dari_user` | `profiles.id` | ❌ MISSING |
| 13 | `profiles!ke_user` | `aset_mutasi.ke_user` | `profiles.id` | ❌ MISSING |
| 14 | `profiles!inner` (implicit) | `submission_tasks.user_id`, `submission_assignments.user_id` | `profiles.id` | ❌ MISSING |
| 15 | `aset!aset_id` | `aset_penyusutan_history.aset_id`, `aset_opname_items.aset_id`, `aset_mutasi.aset_id`, `aset_pemeliharaan.aset_id`, `aset_bast_items.aset_id` | `aset.id` | ❌ MISSING |
| 16 | `aset_opname!opname_id` | `aset_opname_items.opname_id` | `aset_opname.id` | ❌ MISSING |
| 17 | `attendance_shifts!shift_id` | `attendance_shift_assignment.shift_id`, `shifts` | `attendance_shifts.id` | ❌ MISSING |
| 18 | `work_schedule!schedule_id` | `work_schedule_assignment.schedule_id` | `work_schedule.id` | ❌ MISSING |
| 19 | `lokasi_gedung!gedung_id` | `lokasi_lantai.gedung_id` | `lokasi_gedung.id` | ❌ MISSING |
| 20 | `forms!form_id` | `form_wizard_drafts.form_id` (dipakai di `form-deadline-reminder`) | `forms.id` | ⚠ hanya `form_submissions.form_id` yang punya FK; alias yang di-embed di `form_wizard_drafts` ❌ MISSING |
| 21 | `form_submissions!inner` | `form_submission_files.submission_id`, dashboard services | `form_submissions.id` | ❌ MISSING |
| 22 | `permohonan!permohonan_id` | `submission_dispositions.permohonan_id` | `permohonan.id` | ❌ MISSING |

---

## 4. Tabel Temuan (Severity × File × Query)

Sumber lokasi diverifikasi dari `rg` pada `src/**/*.ts`. Line = baris awal `.select(...)`.

| Severity | File | Line | Relationship (hint) | Status | Penyebab | Dampak |
|---|---|---|---|---|---|---|
| Critical | `src/routes/permohonan.$id.tsx` | 103 | `permohonan → opd!opd_id` | ❌ FK missing | `permohonan.opd_id` tidak punya constraint FK ke `opd.id` | **Halaman detail permohonan gagal load** → error yang user laporkan |
| Critical | `src/lib/permohonan-list.functions.ts` | 21 | `permohonan → opd!opd_id` | ❌ | idem | Daftar permohonan warga & admin gagal |
| Critical | `src/lib/permohonan-public.functions.ts` | 37 | `permohonan → opd!opd_id` | ❌ | idem | Endpoint cek permohonan publik gagal |
| Critical | `src/lib/queries.ts` | 110 (`layananAllWithOpdQueryOptions`) | `layanan_publik → opd!opd_id` | ❌ | `layanan_publik.opd_id` FK belum dibuat (hanya `document_template_id` yang ada) | Daftar layanan publik di landing/`layanan.index` gagal |
| Critical | `src/lib/aset.functions.ts` | 151, 183 | `aset → opd!opd_id`, `aset → profiles!pemegang_user_id` | ❌ | Kolom ada, FK tidak | Modul aset (list, kartu) rusak |
| Critical | `src/lib/aset-mutasi.functions.ts` | 23, 131 | `aset_mutasi → opd!dari_opd`, `opd!ke_opd`, `profiles!dari_user`, `profiles!ke_user`, `aset!aset_id` | ❌ | idem | Modul mutasi aset rusak total |
| Critical | `src/lib/aset-bast.functions.ts` | 138, 162, 170 | `profiles!pemberi_user`, `profiles!penerima_user`, `opd!opd_id`, `aset!aset_id` | ❌ | idem | BAST rusak |
| Critical | `src/lib/aset-opname.functions.ts` | 94, 119, 143 | `opd!opd_id`, `aset!aset_id`, `aset_opname!opname_id` | ❌ | idem | Opname rusak |
| Critical | `src/lib/aset-susut.functions.ts` | 46 | `aset!aset_id` | ❌ | idem | Laporan susut aset rusak |
| Critical | `src/lib/aset-advanced.functions.ts` | 167 | `aset!aset_id`, `opd!opd_id` | ❌ | idem | Verifikasi kampanye aset rusak |
| Critical | `src/lib/asn.functions.ts` | 95, 108, 289, 314 | `opd!opd_id`, `profiles!user_id` | ❌ | idem | Modul ASN (kantor QR, absensi) rusak |
| Critical | `src/lib/asn-advanced.functions.ts` | 53, 148 | `opd!opd_id`, `work_schedule!schedule_id` | ❌ | idem | Jadwal ASN rusak |
| Critical | `src/lib/shifts.functions.ts` | 157 | `attendance_shifts!shift_id` | ❌ | idem | Shift assignment rusak |
| Critical | `src/lib/dataset.functions.ts` | 109, 125, 147, 258, 293, 301 | `opd!opd_pemilik_id`, `profiles!oleh_user_id`, `opd!opd_id` | ❌ | Kolom `opd_pemilik_id`/`oleh_user_id` ada; FK tidak | Manajemen & review dataset rusak |
| Critical | `src/lib/forms-extras.functions.ts` | 27, 115, 143, 291, 330, 346, 408 | `profiles!oleh`, `opd!opd_pemilik_id`, `profiles!user_id`, `profiles!created_by` | ❌ | idem | Modul form (draft, submission, versi) rusak |
| Critical | `src/lib/forms-options.functions.ts` | 42 | `opd!opd_id` | ❌ | idem | Dropdown assignment form rusak |
| Critical | `src/lib/leave.functions.ts` | 42 | `profiles!user_id` | ❌ | idem | Cuti rusak |
| Critical | `src/lib/overtime.functions.ts` | 54 | `profiles!user_id` | ❌ | idem | Lembur rusak |
| Critical | `src/lib/payroll.functions.ts` | 29 | `opd!opd_id` | ❌ | idem | Payroll rusak |
| Critical | `src/lib/disposisi.functions.ts` | 54 | `permohonan!permohonan_id` | ❌ | `submission_dispositions.permohonan_id` tidak FK ke `permohonan.id` | Disposisi rusak |
| Critical | `src/lib/uploads.functions.ts` | 180, 212 | `form_submissions!inner(... forms(opd_pemilik_id))` | ⚠ hanya `form_id` yang punya FK; nested `forms(opd_pemilik_id)` gagal | Nested embed butuh FK `forms.opd_pemilik_id → opd.id` | Modul upload cleanup gagal |
| Critical | `src/features/rbac/admin.functions.ts` | 56, 99 | `profiles → opd!opd_id` | ❌ | `profiles.opd_id` tidak FK ke `opd.id` | RBAC listing rusak |
| High | `src/features/dashboard/services/dashboard-*.service.ts` | 34, 41, 48, 60 (task), 43, 53 (overview) | `form_submissions!inner(opd_id)` | ❌ | Tanpa FK, `!inner` join gagal | Dashboard admin salah / kosong |
| High | `src/routes/api/public/hooks/sla-reminder.ts` | 54 | `profiles!inner(opd_id)` | ❌ | idem | Cron SLA reminder gagal |
| High | `src/routes/api/public/hooks/sla-escalation.ts` | 82 | `profiles!inner(opd_id)` | ❌ | idem | Cron eskalasi gagal |
| High | `src/routes/api/public/hooks/form-deadline-reminder.ts` | 19 | `forms!form_id` | ❌ (jika `form_wizard_drafts.form_id` tidak FK) | idem | Cron reminder deadline gagal |
| High | `src/lib/lokasi.functions.ts` | 23, 122 | `opd!opd_id`, `lokasi_gedung!gedung_id` | ❌ | idem | Master lokasi rusak |
| Medium | `src/lib/aset.functions.ts` | 319 | `profiles!oleh` | ❌ | `aset_riwayat.oleh` tidak FK | Riwayat aset tidak menampilkan nama petugas |

*(Daftar di atas mencakup semua 50+ query hasil grep; setiap alias `opd:opd!opd_id(...)` / `profiles!...` / `aset!aset_id` / dst. bergantung pada FK yang tidak ada.)*

---

## 5. Missing FK — Daftar Lengkap (per constraint yang seharusnya ada)

Diambil dari kombinasi (source column, target) yang dipakai kode & di-declare di migrations. Semua **tidak ada** di DB kecuali 5 di §2.

**Group A — `-> opd.id`**

- `permohonan.opd_id`
- `layanan_publik.opd_id`
- `dataset_template.opd_pemilik_id`
- `dataset_submission.opd_id`
- `forms.opd_pemilik_id`
- `form_submissions.opd_id`
- `aset.opd_id`
- `aset_mutasi.dari_opd`, `aset_mutasi.ke_opd`
- `aset_bast.opd_id`
- `aset_opname.opd_id`
- `aset_verification_item.opd_id`
- `aset_verification_campaign.opd_id`
- `attendance_shifts.opd_id`
- `attendance_shift_assignment.opd_id`
- `work_schedule.opd_id`
- `kantor_qr.opd_id`
- `payroll_periods.opd_id`
- `overtime_requests.opd_id`
- `pengajuan_izin.opd_id`
- `profiles.opd_id`
- `lokasi_gedung.opd_id`
- `lokasi_ruangan.opd_id`
- `bukti_nomor_seq.opd_id`
- `nomor_surat_sequence.opd_id`, `nomor_surat_issued.opd_id`
- `submission_dispositions.opd_id`, `submission_assignments.opd_id`
- (…59 `references opd` di migrations)

**Group B — `-> profiles.id` / `auth.users.id`**

- `permohonan.pemohon_id`
- `aset.pemegang_user_id`, `aset_riwayat.oleh`
- `aset_mutasi.dari_user`, `aset_mutasi.ke_user`, `aset_mutasi.approved_by`
- `aset_bast.pemberi_user`, `aset_bast.penerima_user`
- `dataset_submission.oleh_user_id`
- `form_submissions.user_id`, `form_submission_files.uploaded_by`, `form_submission_comment.oleh`, `form_submission_versions.created_by`
- `overtime_requests.user_id`, `leave_balances.user_id`, `pengajuan_izin.user_id`
- `absensi_asn.user_id`
- `submission_tasks.user_id`, `submission_assignments.user_id`, `submission_dispositions.oleh`
- `permohonan_riwayat.oleh`, `permohonan_berkas.uploaded_by`, `permohonan_rating.user_id`
- `audit_log.user_id`, `notifications.user_id`, `consent_log.user_id`, `push_subscription.user_id`, `verification_logs.user_id`, `rbac_audit.actor_id`, `user_permissions.user_id`, `user_roles.user_id`
- `profiles.verified_by`

**Group C — `-> aset.id`**

- `aset_riwayat.aset_id`, `aset_mutasi.aset_id`, `aset_pemeliharaan.aset_id`, `aset_penyusutan_history.aset_id`, `aset_opname_items.aset_id`, `aset_bast_items.aset_id`, `aset_nilai_buku.aset_id`, `aset_verification_item.aset_id`

**Group D — `-> permohonan.id`**

- `permohonan_riwayat.permohonan_id`, `permohonan_berkas.permohonan_id`, `permohonan_rating.permohonan_id`, `submission_dispositions.permohonan_id`, `submission_escalations.permohonan_id`, `submission_sla_events.permohonan_id`, `dokumen_verifikasi.permohonan_id`, `nomor_surat_issued.permohonan_id`, `generated_documents.permohonan_id`, `bukti_dokumen.permohonan_id`

**Group E — `-> forms.id / form_submissions.id / form_fields.id`**

- `form_submissions.form_id` ✅ (ada)
- `form_fields.form_id`, `form_versions.form_id`, `form_targets.form_id`, `form_assignments.form_id`, `form_wizard_drafts.form_id`, `form_audit_logs.form_id`
- `form_submission_files.submission_id`, `form_submission_comment.submission_id`, `form_submission_versions.submission_id`, `submission_values.submission_id`, `submission_tasks.submission_id`, `submission_dispositions.submission_id`, `submission_assignments.submission_id`, `submission_delegations.submission_id`, `submission_escalations.submission_id`, `submission_sla_events.submission_id`, `submission_versions.submission_id`

**Group F — lain-lain**

- `lokasi_lantai.gedung_id → lokasi_gedung.id`
- `lokasi_ruangan.lantai_id → lokasi_lantai.id`
- `attendance_shift_assignment.shift_id → attendance_shifts.id`
- `work_schedule_assignment.schedule_id → work_schedule.id`
- `document_template_versions.template_id → document_templates.id`
- `document_numbering_sequences.rule_id → document_numbering_rules.id`
- `signature_request_signers.request_id → signature_requests.id`
- `signed_documents.request_id → signature_requests.id`
- `signature_events.request_id → signature_requests.id`
- `workflow_versions.workflow_id → workflow_definitions.id`
- `workflow_nodes.version_id`, `workflow_edges.version_id → workflow_versions.id`
- `workflow_instances.version_id → workflow_versions.id`
- `uat_results.scenario_id → uat_scenarios.id`

*(Total ~195 FK missing sesuai selisih 200 declared − 5 realized.)*

---

## 6. Invalid / Orphan / Duplicate

- **Duplicate constraint:** tidak ada (karena hanya 5 constraint yang ada — mustahil duplikat).
- **Orphan FK** (FK menunjuk tabel yang dihapus): tidak terdeteksi; 5 FK aktif semuanya valid.
- **Orphan table** (tabel tanpa referensi masuk/keluar): banyak — mis. `berita`, `hari_libur`, `desa`, `feature_flags`, `app_setting`, `retention_policies` — mayoritas memang tabel referensi/konfigurasi sehingga bukan bug.
- **Circular reference:** tidak ada karena FK hampir kosong.
- **FK disabled (`NOT VALID`):** tidak ada.
- **Migration overwrite:** file migrasi terakhir `250_fix_grants_admin_all_public.sql` melakukan `GRANT` masal tetapi **tidak menambahkan FK**. Migrasi awal (`010_*`, `020_*`) berisi `CREATE TABLE ... REFERENCES ...` — inilah yang gagal saat runner memasang table sebelum target-nya ada, dan **tidak diulang** setelah tabel target akhirnya dibuat.

---

## 7. Naming Consistency

- Konvensi dominan: `snake_case` + suffix `_id` (`opd_id`, `user_id`, `aset_id`, `form_id`). Konsisten.
- Beberapa kolom tidak memakai suffix `_id` (semantik "role user"): `oleh`, `pemberi_user`, `penerima_user`, `dari_user`, `ke_user`, `dari_opd`, `ke_opd`, `approved_by`, `verified_by`, `uploaded_by`, `created_by`. Ini **valid** dan dipakai konsisten di kode (`profiles!oleh`, `opd!dari_opd`), tetapi karena bukan `<table>_id` PostgREST **wajib** memakai FK-hint eksplisit — sehingga *lebih rawan* kalau FK tidak ada.
- Tidak ditemukan `camelCase` / `idOpd` di source code.

---

## 8. Nullable FK

Sampling kolom kritis (`information_schema.columns`):

- `permohonan.opd_id` — NULLABLE (kode `opd_kinerja_agg()` sudah `WHERE opd_id IS NOT NULL`, aman).
- `permohonan.pemohon_id` — NOT NULL (aman).
- `dataset_submission.opd_id` — NULLABLE (dipakai untuk submission lintas OPD).
- `aset.pemegang_user_id` — NULLABLE (aset tanpa pemegang).
- `aset_mutasi.approved_by` — NULLABLE (pending approval).
- Sisanya sesuai domain; **tidak ditemukan NULLABLE yang berisiko orphan** karena data belum ada.

Warning: setelah FK dibuat nanti, `permohonan.opd_id` yang saat ini NULL akan tetap valid (NULL diperbolehkan FK). Tidak perlu backfill khusus.

---

## 9. Cascade Rules

Tidak dapat diaudit dari DB karena FK hampir tidak ada. Dari migrasi:

- Mayoritas migrasi memakai `ON DELETE CASCADE` untuk anak yang wajib mati bersama parent: `permohonan_riwayat`, `permohonan_berkas`, `permohonan_rating`, `form_submission_*`, `aset_riwayat`, `aset_opname_items`, `signature_request_signers` — pilihan wajar.
- FK ke `auth.users`: memakai `ON DELETE CASCADE` (mis. `profiles`, `user_roles`, `notifications`) — sesuai standar Supabase.
- FK ke `opd`: banyak yang tidak menyertakan `ON DELETE` (default `NO ACTION`) — berisiko menahan penghapusan OPD, tetapi lebih aman dari CASCADE yang menghapus permohonan. **No action needed**.

---

## 10. Index

Tidak dapat memverifikasi FK-index karena FK tidak dibuat. Untuk kolom FK terpakai (§3), sampling `pg_indexes` menunjukkan:

- `permohonan.opd_id` — tidak ada index (Postgres tidak otomatis index FK).
- `aset.opd_id`, `aset.pemegang_user_id` — tidak ada index.
- Kolom `form_submissions.form_id` — ada FK, **tidak** ada index eksplisit → berisiko slow join.
- `user_roles(user_id, role)` — ada UNIQUE index dari definisi tabel.

**Warning:** ketika FK dipulihkan, tambahkan index B-tree pada kolom FK bervolume tinggi (`permohonan.opd_id`, `permohonan.pemohon_id`, `absensi_asn.user_id`, `aset.opd_id`, `form_submissions.opd_id`, `form_submissions.user_id`).

---

## 11. RLS Impact

- 58 dari 124 tabel memiliki RLS aktif; 66 lainnya tanpa RLS (masih dilindungi grant `authenticated`).
- Query embed `permohonan → opd` **tidak** dipengaruhi RLS karena PostgREST menolak lebih dulu di tahap schema-cache (error saat ini muncul **sebelum** RLS dievaluasi). Setelah FK ditambahkan, cek policy `opd`: saat ini `opd` tidak punya policy SELECT publik untuk `anon`, tetapi rute `permohonan.$id.tsx` dijalankan sebagai user login sehingga `authenticated` mendapat SELECT via grant di §migration `250_*`.
- Tidak ada relationship yang akan gagal khusus karena RLS setelah FK dipasang.

---

## 12. Query yang PASTI Menghasilkan Error PostgREST

Semua file di tabel §4 dengan status ❌ akan mengembalikan `PGRST200` / "couldn't find relationship". Yang menjadi keluhan user (`permohonan → opd`) hanya **satu dari 50+** query yang saat ini bermasalah. Menu berikut praktis tidak bisa dipakai:

1. Semua rute permohonan warga (`permohonan.index`, `permohonan.$id`, `cek-permohonan`).
2. `layanan.index` (grid layanan publik).
3. Seluruh menu **Aset** (list, kartu, mutasi, BAST, opname, susut, pemeliharaan, verifikasi kampanye).
4. Seluruh menu **ASN** (kantor QR, jadwal, shift assignment, absensi rekap).
5. **Dataset** (list, review, submission).
6. **Forms** (draft, submission, versi, komentar) — bagian yang memakai embed.
7. **Cuti, Lembur, Payroll**.
8. **Lokasi** (gedung/lantai/ruangan).
9. **RBAC** (list user + OPD).
10. **Cron jobs** SLA reminder, escalation, form deadline reminder.
11. **Disposisi**.

---

## 13. Root Cause Analysis

1. **Runner migrasi per-file dengan flag `--benign`** (`/tmp/runmig*.py` yang dipakai di sesi awal) meng-skip error `already exists`. Tetapi ketika `CREATE TABLE t (... x_id uuid REFERENCES parent(id))` dijalankan sebelum `parent` ada, Postgres error `relation "parent" does not exist`. Pada pass berikutnya, tabel `t` sudah dibuat sebagian (rollback per statement pada beberapa dialek tidak berlaku karena file dijalankan sebagai satu transaksi yang rollback penuh) — tetapi runner tetap menandai file `applied` setelah pass di mana file "sukses" (padahal sebagian ALTER ADD FK bawaannya sudah dipisah / atau file di-*shadow* oleh migrasi manual tambahan seperti `catchup*.sql` yang hanya membuat kolom, bukan FK).
2. **Migrasi "catch-up manual"** yang ditulis lewat tool `supabase--migration` (mis. `bukti_dokumen`, `layanan_publik.document_template_id`) **hanya menambah kolom + FK yang ditulis eksplisit**. Karena penulisan manual hanya mengatasi error TS satu-per-satu, hanya 5 FK yang terbuat.
3. **Grant sweep `250_*`** memperbaiki 403 tetapi tidak menyentuh FK, sehingga permasalahan tidak terlihat sampai user membuka detail permohonan.
4. **PostgREST schema cache** dibangun ulang setiap kali struktur berubah. Karena FK tidak pernah ada, cache selalu menganggap tidak ada relasi antar tabel — memicu `PGRST200`.

---

## 14. Production Risk

| Level | Ringkasan |
|---|---|
| **Critical** | 19 pola relasi + 50+ query. Menu inti (permohonan, layanan, aset, ASN, dataset, forms, cuti, lembur, payroll, disposisi, RBAC) **tidak dapat dipakai** pengguna akhir. Cron SLA/eskalasi diam-diam gagal → SLA tidak ter-track. |
| **High** | Dashboard admin menampilkan angka 0/salah karena embed `form_submissions!inner(opd_id)` gagal. Pipeline retensi upload gagal. |
| **Medium** | Tampilan riwayat aset & disposisi tanpa nama petugas. |
| **Low** | Naming inkonsisten kolom peran (`oleh`, `dari_user`) — hanya masalah kejelasan, tidak menyebabkan bug bila FK dibuat dengan hint eksplisit. |

---

## 15. Rekomendasi (Tidak Diterapkan)

> Berikut hanya rekomendasi teknis. **Tidak dijalankan** sesuai instruksi audit read-only.

### 15.1 Rebuild FK (contoh SQL — masukkan ke migrasi baru saat diminta)

```sql
-- Group A: -> opd(id)
ALTER TABLE public.permohonan
  ADD CONSTRAINT permohonan_opd_id_fkey
  FOREIGN KEY (opd_id) REFERENCES public.opd(id) ON DELETE SET NULL;

ALTER TABLE public.permohonan
  ADD CONSTRAINT permohonan_pemohon_id_fkey
  FOREIGN KEY (pemohon_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.layanan_publik
  ADD CONSTRAINT layanan_publik_opd_id_fkey
  FOREIGN KEY (opd_id) REFERENCES public.opd(id) ON DELETE SET NULL;

-- Ulangi pola untuk setiap kolom di §5 Group A..F.
-- Untuk masing-masing, tambahkan index:
CREATE INDEX IF NOT EXISTS permohonan_opd_id_idx ON public.permohonan(opd_id);
CREATE INDEX IF NOT EXISTS permohonan_pemohon_id_idx ON public.permohonan(pemohon_id);
-- ...
```

Setelah FK ditambahkan, jalankan `NOTIFY pgrst, 'reload schema';` (atau restart PostgREST) supaya schema cache PostgREST me-reload.

### 15.2 Verifikasi otomatis di CI

- Tambahkan script CI yang mem-parse semua embed `<table>!<column>` dari `src/**/*.ts` lalu memeriksa keberadaan constraint FK di `information_schema.table_constraints`. Jika ada mismatch, gagalkan build. Ini mencegah regresi.

### 15.3 Prosedur migrasi masa depan

- Jangan pakai runner multi-pass dengan skip-benign untuk migrasi yang mengandung `CREATE TABLE ... REFERENCES ...`. Gunakan urutan asli file (angka prefiks) dalam **satu transaksi per file**, hentikan pada error pertama, dan pisahkan `ADD CONSTRAINT FOREIGN KEY` ke file terpisah setelah semua tabel dibuat.

### 15.4 Prioritas perbaikan (bila nanti dieksekusi)

1. Group A (opd), Group D (permohonan), Group E (forms/submissions) — memulihkan menu utama.
2. Group C (aset) — memulihkan modul aset.
3. Group B (profiles/users) — memulihkan tampilan nama pengguna.
4. Group F — modul pendukung.

---

## 16. Ketertelusuran

Semua temuan dapat ditelusuri ke:

- `information_schema.table_constraints` query (§2) — 5 FK aktual.
- Grep `rg -o "[a-zA-Z_]+![a-zA-Z_]+"` pada `src/**/*.ts` (§3, §4).
- `rg "references|foreign key" supabase/migrations/` — 355 kemunculan (§1, §13).
- File & line di tabel §4 semua dapat diverifikasi ulang.

*End of report.*

# Perbaikan: Login gagal & nama kabupaten hilang saat koneksi backend terputus sebentar

## Temuan

Backend (database & autentikasi) saat ini sehat dan merespons normal. Jadi ini bukan backend yang "mati", melainkan **gangguan sesaat pada satu permintaan** (jaringan lambat/putus sekejap) yang tidak ditangani oleh aplikasi. Dua gejala yang Anda lihat berasal dari akar yang sama:

1. **Nama kabupaten hilang dari header.**
   Identitas situs (lambang, "PEMERINTAH KABUPATEN", nama kabupaten) diambil sekali setiap halaman dimuat. Bila permintaan itu gagal:
   - Di sisi server tidak ada salinan cadangan sama sekali, sehingga halaman dikirim dengan teks bawaan "Nama Kabupaten" — terlihat seperti nama kabupaten hilang.
   - Tidak ada percobaan ulang; satu kegagalan langsung berakhir pada teks bawaan.

2. **Tidak bisa masuk padahal kredensial benar.**
   Proses masuk mengirim satu permintaan tanpa percobaan ulang dan tanpa batas waktu. Kalau permintaan itu tersendat, pesan yang muncul berupa kegagalan umum, sehingga terkesan "akun ditolak" padahal sebenarnya koneksi yang bermasalah. Pemuatan hak akses setelah masuk sudah punya percobaan ulang, tapi proses masuknya sendiri belum.

Keduanya terjadi bersamaan karena keduanya memakai satu jalur koneksi yang sama ke backend.

## Yang akan diperbaiki (terarah, tanpa mengubah tampilan)

1. **Identitas situs tahan gangguan**
   - Tambahkan percobaan ulang singkat (2 kali, jeda bertahap) plus batas waktu saat mengambil identitas situs.
   - Simpan salinan terakhir yang berhasil di sisi server (dalam memori) agar halaman tetap menampilkan nama kabupaten yang benar walau permintaan sedang gagal.
   - Bila benar-benar belum pernah ada data, tampilkan teks netral, bukan placeholder yang menyesatkan.
   - Muat ulang identitas secara diam-diam ketika koneksi internet kembali tersambung.

2. **Masuk akun tahan gangguan**
   - Percobaan ulang otomatis hanya untuk kegagalan koneksi (bukan untuk kata sandi salah, agar tidak berisiko mengunci akun).
   - Batas waktu yang jelas, dan pesan yang membedakan: "kata sandi salah" vs "koneksi ke server bermasalah, coba lagi".
   - Tombol masuk tetap bisa dicoba lagi tanpa memuat ulang halaman.

3. **Tanpa perubahan lain**
   Tidak menyentuh aturan akses, peran, alur pengalihan halaman, tata letak, atau dashboard yang sudah berjalan.

## Detail teknis

- `src/lib/site-settings.ts`: bungkus `getSiteBranding` dengan helper retry + `AbortSignal.timeout`; tambahkan cache modul (last-known-good) yang dipakai saat SSR; pertahankan perilaku "jangan timpa cache saat gagal"; tambahkan listener `online` untuk invalidasi query `site-branding`.
- `src/routes/__root.tsx`: `ensureQueryData` tetap, tetapi kegagalan tidak boleh memaksa nilai default — ambil dari cache modul.
- `src/routes/auth.tsx`: pada `signInWithPassword`, bedakan error jaringan (`Failed to fetch`/timeout) dari `invalid_credentials`; retry 2x hanya untuk error jaringan; pesan toast disesuaikan.
- Tidak ada perubahan database, RLS, RPC, atau middleware autentikasi.

## Verifikasi

- Simulasikan kegagalan jaringan di browser: header tetap menampilkan nama kabupaten, dan percobaan masuk memberi pesan koneksi yang jelas lalu berhasil saat jaringan pulih.
- Masuk normal sebagai superadmin tetap berhasil; kata sandi salah tetap ditolak dengan pesan yang benar.
- Cek ponsel (360px) dan desktop (1280px), tanpa error konsol.

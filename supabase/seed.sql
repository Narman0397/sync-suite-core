--
-- PostgreSQL database dump
--

\restrict Mxuxr1t2BfohDvBvecsRNgYWVNs4vGCtBn0efQRfXUgachC48SNWthp3OSDy6tE

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: app_setting; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.app_setting VALUES
	('branding.nama_instansi', '"Pemerintah Daerah"', '2026-07-27 12:02:34.328256+00', 'internal', false),
	('branding.nama_singkat', '"PEMDA"', '2026-07-27 12:02:34.328256+00', 'internal', false),
	('branding.tagline', '"Pelayanan Publik Terpadu"', '2026-07-27 12:02:34.328256+00', 'internal', false),
	('show_opd_directory', '{"visible": true}', '2026-07-29 05:23:51.973124+00', 'public', true),
	('data_terpadu_visible_public', '{"visible": true}', '2026-07-29 05:23:51.973124+00', 'public', true),
	('site_branding', '{"cta_desc": "Sampaikan langsung melalui kanal LAPOR! Setiap laporan dipantau dan ditindaklanjuti oleh OPD terkait.", "logo_url": "https://dvpakjbnrywwsjjsslnb.supabase.co/storage/v1/object/sign/branding/logo-1785252505659.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9iOTUyOGVlZS05NTQxLTQ5ZDItOTIyMS01OGEwYmUxMjJmYzciLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJicmFuZGluZy9sb2dvLTE3ODUyNTI1MDU2NTkucG5nIiwic2NvcGUiOiJkb3dubG9hZCIsImlhdCI6MTc4NTI1MjUwNiwiZXhwIjoxODE2Nzg4NTA2fQ.lAZPd7W7QxVUtE8YaxnNAqzFMq71enxmHGjwSrVEsVs", "cta_title": "Punya keluhan atau aspirasi?", "brand_name": "BUTON SELATAN", "footer_org": "Pemerintah Kabupaten", "hero_bg_url": "", "brand_prefix": "PEMERINTAH KABUPATEN", "footer_email": "—", "footer_phone": "—", "hero_eyebrow": "Portal Resmi Pemerintah", "pilar_1_desc": "Semua dataset pemerintah dalam satu standar — terbuka, terverifikasi, dan dapat diunduh.", "pilar_2_desc": "Warga cukup satu akun untuk seluruh layanan: adminduk, perizinan, kesehatan, hingga pajak.", "pilar_3_desc": "Dashboard kinerja, anggaran, dan capaian program publik dapat dipantau langsung.", "top_bar_text": "Portal Resmi Pemerintah Kabupaten", "hero_subtitle": "Akses seluruh layanan publik dan data pemerintah terpadu dalam satu tempat — cepat, transparan, dan terverifikasi.", "pilar_1_title": "Satu Data Terpadu", "pilar_2_title": "Pelayanan Sentralistik", "pilar_3_title": "Transparansi Real-time", "direktori_desc": "Kenali setiap OPD dan layanan yang dikelolanya.", "footer_address": "—", "footer_tagline": "Melayani dengan integritas & data", "cta_btn_primary": "Lapor Sekarang", "direktori_title": "Dinas & Perangkat Daerah", "meta_site_title": "Portal Resmi Pemerintah Kabupaten", "admin_brand_name": "Dashboard Admin", "hero_btn_primary": "Mulai Layanan", "hero_title_line1": "Satu Pintu,", "hero_title_line2": "Satu Data,", "hero_title_line3": "Satu Pelayanan.", "cta_btn_secondary": "Tentang Pemerintah", "direktori_eyebrow": "Direktori OPD", "footer_description": "Situs resmi pemusatan pelayanan publik dan data terintegrasi. Transparan, terpadu, dan dapat diakses kapan saja.", "hero_btn_secondary": "Lihat Satu Data", "meta_site_description": "Portal resmi pelayanan publik dan satu data Pemerintah Kabupaten."}', '2026-07-28 15:41:58.212891+00', 'public', true),
	('village_verification', '{"mode": "block_permohonan", "enabled": true}', '2026-07-28 15:43:27.350881+00', 'internal', false),
	('kinerja_opd_visible_public', '{"visible": true}', '2026-07-29 05:23:51.973124+00', 'public', true) ON CONFLICT DO NOTHING;


--
-- Data for Name: desa; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.desa VALUES
	('001b0923-5483-45aa-aba9-90a2197f084b', 'Poogalampa', 'Batauga', true, '2026-07-27 23:37:10.715186+00', '2026-07-27 23:37:10.715186+00'),
	('f82dd9d6-5112-45eb-b727-4b92f0d1b181', 'Bola', 'Batauga', true, '2026-07-27 23:37:25.012204+00', '2026-07-27 23:37:25.012204+00'),
	('ea21d3d5-d5bd-4368-97cd-c131c0993c0a', 'Lampanairi', 'Batauga', true, '2026-07-27 23:39:27.082795+00', '2026-07-27 23:39:27.082795+00') ON CONFLICT DO NOTHING;


--
-- Data for Name: hari_libur; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.hari_libur VALUES
	('5c7f6dbf-b5b8-419d-8378-228326328b95', '2026-01-01', 'Tahun Baru Masehi', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL),
	('04911cbc-2caa-468d-a676-34a12bdef1b8', '2026-02-17', 'Tahun Baru Imlek', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL),
	('b21ef611-e042-414b-af8a-dc2171879c6e', '2026-03-19', 'Hari Raya Nyepi', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL),
	('8923620e-fbe7-4a4d-b5a7-a656dcd0b8c5', '2026-03-20', 'Wafat Isa Al Masih', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL),
	('da4350a5-25bb-4d40-a047-8902375dc4d3', '2026-05-01', 'Hari Buruh Internasional', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL),
	('6d1c427f-605f-4858-99fa-e13ad9d068e6', '2026-05-14', 'Kenaikan Isa Al Masih', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL),
	('ade8c391-db7d-4b43-82c7-7406e90d958d', '2026-05-27', 'Hari Raya Idul Adha', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL),
	('a30bf312-5310-4baf-b4fd-167565936c34', '2026-06-01', 'Hari Lahir Pancasila', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL),
	('94569b32-98b5-4fe6-90da-dc9f0477f77e', '2026-06-17', 'Tahun Baru Islam 1448 H', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL),
	('2a9600e5-c1fd-46de-9d91-75e8bcd59dfa', '2026-08-17', 'Hari Kemerdekaan RI', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL),
	('f921c62a-5fef-4caf-91d6-ec772f75d54e', '2026-08-26', 'Maulid Nabi Muhammad SAW', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL),
	('e4bf4d67-d384-4fdb-b994-b6968d2081a7', '2026-12-25', 'Hari Raya Natal', 'nasional', '2026-07-27 23:34:51.273672+00', true, NULL) ON CONFLICT DO NOTHING;


--
-- Data for Name: kategori_layanan; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.kategori_layanan VALUES
	('f579dada-2e7f-4570-9c89-0245037be0e6', 'Administrasi Kependudukan', 'adminduk', 7, 'Layanan terkait dokumen kependudukan', true, '2026-07-27 12:05:57.481548+00', '2026-07-27 12:05:57.481548+00', NULL),
	('938fbbf6-82f5-4652-946b-7949b4ffedb1', 'Perizinan Usaha', 'perizinan-usaha', 14, 'Pengurusan izin usaha & investasi', true, '2026-07-27 12:05:57.481548+00', '2026-07-27 12:05:57.481548+00', NULL),
	('b6dd41f8-fdd5-4039-871e-29c595afb258', 'Pendidikan', 'pendidikan', 10, 'Layanan bidang pendidikan', true, '2026-07-27 12:05:57.481548+00', '2026-07-27 12:05:57.481548+00', NULL),
	('9648f720-8a4d-45a0-a02d-461936c9cd85', 'Kesehatan', 'kesehatan', 7, 'Layanan kesehatan masyarakat', true, '2026-07-27 12:05:57.481548+00', '2026-07-27 12:05:57.481548+00', NULL),
	('e8b0e244-7721-4710-9999-94ff1eeb67f7', 'Sosial', 'sosial', 10, 'Bantuan sosial & pemberdayaan', true, '2026-07-27 12:05:57.481548+00', '2026-07-27 12:05:57.481548+00', NULL),
	('9dbc7857-dee6-457a-91f0-698239e53d8a', 'Pertanahan', 'pertanahan', 14, 'Layanan pertanahan', true, '2026-07-27 12:05:57.481548+00', '2026-07-27 12:05:57.481548+00', NULL),
	('608b7d86-ee0d-4116-bef1-d48974623e82', 'Lingkungan', 'lingkungan', 14, 'Izin & layanan lingkungan', true, '2026-07-27 12:05:57.481548+00', '2026-07-27 12:05:57.481548+00', NULL),
	('d88dea28-8af1-43a3-b2db-6592b3a4fc19', 'Lainnya', 'lainnya', 7, 'Layanan umum lainnya', true, '2026-07-27 12:05:57.481548+00', '2026-07-27 12:05:57.481548+00', NULL) ON CONFLICT DO NOTHING;


--
-- Data for Name: opd; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.opd VALUES
	('11111111-1111-1111-1111-000000000001', 'Sekretariat Daerah', 'SETDA', '{umum,pemerintahan}', '2026-07-27 23:34:50.581796+00', '{kode}/{seq}/{singkatan}/{tahun}', '470', 'setda'),
	('11111111-1111-1111-1111-000000000002', 'Dinas Kependudukan & Pencatatan Sipil', 'DISDUKCAPIL', '{Adminduk,"Akta Kelahiran",KTP-el,"Kartu Keluarga"}', '2026-07-27 23:34:50.581796+00', '{kode}/{seq}/{singkatan}/{tahun}', '471', 'disdukcapil'),
	('11111111-1111-1111-1111-000000000003', 'Dinas Penanaman Modal & PTSP', 'DPMPTSP', '{"Perizinan Usaha","IMB / PBG","Izin Reklame"}', '2026-07-27 23:34:50.581796+00', '{kode}/{seq}/{singkatan}/{tahun}', '503', 'dpmptsp'),
	('11111111-1111-1111-1111-000000000004', 'Dinas Perhubungan', 'DISHUB', '{"Izin Trayek",Parkir,"Pengaduan Lalin"}', '2026-07-27 23:34:50.581796+00', '{kode}/{seq}/{singkatan}/{tahun}', '551', 'dishub'),
	('11111111-1111-1111-1111-000000000005', 'Dinas Kesehatan', 'DINKES', '{"Izin Praktik","Layanan Kesehatan",Vaksinasi}', '2026-07-27 23:34:50.581796+00', '{kode}/{seq}/{singkatan}/{tahun}', '440', 'dinkes'),
	('11111111-1111-1111-1111-000000000006', 'Dinas Pendidikan', 'DISDIK', '{Pendidikan,PPDB}', '2026-07-27 23:34:50.581796+00', '{kode}/{seq}/{singkatan}/{tahun}', '420', 'disdik'),
	('11111111-1111-1111-1111-000000000007', 'Dinas Sosial', 'DINSOS', '{"Bantuan Sosial",DTKS}', '2026-07-27 23:34:50.581796+00', '{kode}/{seq}/{singkatan}/{tahun}', '460', 'dinsos'),
	('11111111-1111-1111-1111-000000000008', 'Badan Kepegawaian & PSDM', 'BKPSDM', '{Kepegawaian,ASN}', '2026-07-27 23:34:50.581796+00', '{kode}/{seq}/{singkatan}/{tahun}', '800', 'bkpsdm') ON CONFLICT DO NOTHING;


--
-- Data for Name: layanan_publik; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.layanan_publik VALUES
	('c77bea1c-fd5c-4c69-a8ac-236b947e3f20', 'Penerbitan Akta Kelahiran', 'akta-kelahiran', 'Layanan penerbitan Akta Kelahiran untuk anak yang baru lahir.', NULL, '11111111-1111-1111-1111-000000000002', '- Surat Keterangan Kelahiran dari bidan/RS
- Fotokopi KK & KTP orang tua
- Fotokopi Buku Nikah orang tua', '1. Pengajuan online
2. Verifikasi berkas
3. Pencetakan akta
4. Pengambilan/kirim digital', true, 1, 7, '2026-07-27 23:34:51.101029+00', '2026-07-27 23:34:51.101029+00', 'UU No. 24 Tahun 2013 tentang Adminduk', 'Gratis', 'Akta Kelahiran', 'Senin–Jumat 08:00–15:00', NULL, NULL, NULL, NULL, NULL, 'Loket pengaduan atau menu "Lapor Bupati"', NULL, 'Kami berkomitmen menerbitkan Akta Kelahiran maksimal 7 hari kerja.', '[]', NULL, NULL, NULL, false, NULL),
	('bdf916fb-9b93-4a0d-97d3-6e6f55ba2a14', 'Pencetakan KTP Elektronik', 'ktp-el', 'Perekaman dan pencetakan KTP-el bagi warga usia 17 tahun ke atas.', NULL, '11111111-1111-1111-1111-000000000002', '- Fotokopi KK
- Surat Pengantar RT/RW
- Foto berwarna 3x4', '1. Pengajuan online
2. Perekaman biometrik
3. Pencetakan
4. Pengambilan', true, 2, 14, '2026-07-27 23:34:51.101029+00', '2026-07-27 23:34:51.101029+00', 'UU No. 24 Tahun 2013', 'Gratis', 'KTP-el', 'Senin–Jumat 08:00–15:00', NULL, NULL, NULL, NULL, NULL, 'Menu "Lapor Bupati"', NULL, 'Selesai maksimal 14 hari kerja setelah perekaman.', '[]', NULL, NULL, NULL, false, NULL),
	('e53624eb-c566-40a6-84f4-b8d1d4f651cc', 'Perubahan Kartu Keluarga', 'kk-perubahan', 'Permohonan perubahan data KK (penambahan/pengurangan anggota).', NULL, '11111111-1111-1111-1111-000000000002', '- KK asli
- KTP pemohon
- Surat pengantar RT/RW
- Dokumen pendukung perubahan', '1. Pengajuan
2. Verifikasi
3. Penerbitan KK baru', true, 3, 5, '2026-07-27 23:34:51.101029+00', '2026-07-27 23:34:51.101029+00', 'UU No. 24 Tahun 2013', 'Gratis', 'Kartu Keluarga baru', 'Senin–Jumat 08:00–15:00', NULL, NULL, NULL, NULL, NULL, 'Menu "Lapor Bupati"', NULL, 'Selesai maksimal 5 hari kerja.', '[]', NULL, NULL, NULL, false, NULL),
	('35692262-afab-49ca-a711-fd4d3aa85787', 'Penerbitan NIB Usaha Mikro', 'nib-umkm', 'Penerbitan NIB untuk pelaku Usaha Mikro dan Kecil.', NULL, '11111111-1111-1111-1111-000000000003', '- KTP pemilik usaha
- NPWP (jika ada)
- Surat keterangan domisili usaha', '1. Pengajuan
2. Verifikasi
3. Penerbitan NIB via OSS', true, 1, 3, '2026-07-27 23:34:51.101029+00', '2026-07-27 23:34:51.101029+00', 'PP No. 5 Tahun 2021', 'Gratis', 'NIB', 'Senin–Jumat 08:00–15:00', NULL, NULL, NULL, NULL, NULL, 'Menu "Lapor Bupati"', NULL, 'NIB terbit paling lama 3 hari kerja.', '[]', NULL, NULL, NULL, false, NULL),
	('a15c8be4-5f55-4475-9e4f-797501394b8b', 'Persetujuan Bangunan Gedung (PBG)', 'pbg', 'Permohonan PBG untuk pembangunan rumah tinggal / bangunan.', NULL, '11111111-1111-1111-1111-000000000003', '- KTP & NPWP pemohon
- Sertifikat tanah
- Gambar teknis bangunan
- SPPT PBB', '1. Konsultasi
2. Pengajuan
3. Verifikasi teknis
4. Penerbitan PBG', true, 2, 28, '2026-07-27 23:34:51.101029+00', '2026-07-27 23:34:51.101029+00', 'UU CK & PP No. 16/2021', 'Sesuai perhitungan retribusi', 'Sertifikat PBG', 'Senin–Jumat 08:00–15:00', NULL, NULL, NULL, NULL, NULL, 'Menu "Lapor Bupati"', NULL, 'Terbit maksimal 28 hari kerja setelah berkas lengkap.', '[]', NULL, NULL, NULL, false, NULL),
	('0a890053-9356-4d0f-91cb-1ab45743e756', 'Izin Trayek Angkutan', 'izin-trayek', 'Permohonan izin/perpanjangan trayek angkutan kota.', NULL, '11111111-1111-1111-1111-000000000004', '- KTP pemohon
- STNK & buku uji kendaraan
- SIM sesuai kelas', '1. Pengajuan
2. Verifikasi trayek
3. Penerbitan kartu izin', true, 1, 10, '2026-07-27 23:34:51.101029+00', '2026-07-27 23:34:51.101029+00', 'UU No. 22 Tahun 2009 LLAJ', 'Sesuai retribusi daerah', 'Kartu Izin Trayek', 'Senin–Jumat 08:00–15:00', NULL, NULL, NULL, NULL, NULL, 'Menu "Lapor Bupati"', NULL, 'Terbit maksimal 10 hari kerja.', '[]', NULL, NULL, NULL, false, NULL),
	('422b0d55-d95b-4779-b9d3-3a2d080f64d3', 'Pengaduan Fasilitas Lalu Lintas', 'pengaduan-lalin', 'Pengaduan kerusakan rambu / marka / APILL.', NULL, '11111111-1111-1111-1111-000000000004', '- Foto lokasi
- Titik koordinat / alamat jelas', '1. Pengaduan
2. Verifikasi lapangan
3. Tindak lanjut perbaikan', true, 2, 7, '2026-07-27 23:34:51.101029+00', '2026-07-27 23:34:51.101029+00', 'UU No. 22 Tahun 2009', 'Gratis', 'Perbaikan fasilitas', '24 jam', NULL, NULL, NULL, NULL, NULL, 'Loket pengaduan / online', NULL, 'Ditindaklanjuti maksimal 7 hari kerja.', '[]', NULL, NULL, NULL, false, NULL),
	('0bfac21e-6482-4ed1-872c-cffd588f3058', 'Surat Izin Praktik (SIP) Tenaga Kesehatan', 'sip', 'Permohonan SIP untuk dokter/bidan/perawat.', NULL, '11111111-1111-1111-1111-000000000005', '- STR aktif
- Surat rekomendasi organisasi profesi
- Fotokopi ijazah
- Pas foto', '1. Pengajuan
2. Verifikasi
3. Penerbitan SIP', true, 1, 14, '2026-07-27 23:34:51.101029+00', '2026-07-27 23:34:51.101029+00', 'Permenkes No. 2052/2011', 'Sesuai retribusi', 'SIP', 'Senin–Jumat 08:00–15:00', NULL, NULL, NULL, NULL, NULL, 'Menu "Lapor Bupati"', NULL, 'Terbit maksimal 14 hari kerja.', '[]', NULL, NULL, NULL, false, NULL),
	('0a5c1ff7-000b-442b-91c6-f60f7ed6a80a', 'Vaksinasi Balita', 'vaksinasi-balita', 'Pendaftaran jadwal vaksinasi balita di Puskesmas.', NULL, '11111111-1111-1111-1111-000000000005', '- KIA / KMS
- KK
- KTP orang tua', '1. Pendaftaran online
2. Konfirmasi jadwal
3. Vaksinasi di Puskesmas', true, 2, 3, '2026-07-27 23:34:51.101029+00', '2026-07-27 23:34:51.101029+00', 'Permenkes Imunisasi', 'Gratis', 'Layanan vaksinasi', 'Senin–Jumat 08:00–12:00', NULL, NULL, NULL, NULL, NULL, 'Puskesmas terdekat', NULL, 'Jadwal dikonfirmasi maksimal 3 hari kerja.', '[]', NULL, NULL, NULL, false, NULL),
	('92baac0f-4d01-467d-80d7-51992e8a577d', 'Pendaftaran PPDB', 'ppdb', 'Pendaftaran Peserta Didik Baru SD/SMP negeri.', NULL, '11111111-1111-1111-1111-000000000006', '- Akta kelahiran
- KK
- Ijazah sebelumnya', '1. Pendaftaran online
2. Verifikasi
3. Pengumuman', true, 1, 14, '2026-07-27 23:34:51.101029+00', '2026-07-27 23:34:51.101029+00', 'Permendikbud PPDB', 'Gratis', 'Bukti diterima', 'Sesuai jadwal PPDB', NULL, NULL, NULL, NULL, NULL, 'Panitia PPDB', NULL, 'Sesuai kalender PPDB tahun berjalan.', '[]', NULL, NULL, NULL, false, NULL),
	('3dade118-0f52-4c68-9e98-89ebee34a6d1', 'Rekomendasi DTKS', 'dtks', 'Permohonan verifikasi & rekomendasi Data Terpadu Kesejahteraan Sosial.', NULL, '11111111-1111-1111-1111-000000000007', '- KTP & KK
- Surat keterangan tidak mampu', '1. Pengajuan
2. Verifikasi lapangan
3. Rekomendasi', true, 1, 14, '2026-07-27 23:34:51.101029+00', '2026-07-27 23:34:51.101029+00', 'Permensos DTKS', 'Gratis', 'Surat Rekomendasi', 'Senin–Jumat 08:00–15:00', NULL, NULL, NULL, NULL, NULL, 'Menu "Lapor Bupati"', NULL, 'Terbit maksimal 14 hari kerja.', '[]', NULL, NULL, NULL, false, NULL) ON CONFLICT DO NOTHING;


--
-- Data for Name: master_jabatan; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.master_jabatan VALUES
	('75239d6c-5ac7-41f7-86d4-1c95cf5c5fd4', 'KEPALA_DINAS', 'Kepala Dinas', 'Struktural', 10, true, '2026-07-27 11:52:49.259566+00', '2026-07-27 11:52:49.259566+00', NULL, false),
	('ce661f87-b5fc-4621-83a6-bc4b778fd98f', 'SEKRETARIS', 'Sekretaris', 'Struktural', 20, true, '2026-07-27 11:52:49.259566+00', '2026-07-27 11:52:49.259566+00', NULL, false),
	('3f024f0a-7c82-492d-ac23-6c110ef2568e', 'KABID', 'Kepala Bidang', 'Struktural', 30, true, '2026-07-27 11:52:49.259566+00', '2026-07-27 11:52:49.259566+00', NULL, false),
	('2c2512c0-acdf-46f3-9438-e2dfe907da44', 'KASUBAG', 'Kepala Sub Bagian', 'Struktural', 40, true, '2026-07-27 11:52:49.259566+00', '2026-07-27 11:52:49.259566+00', NULL, false),
	('ffcfffe9-4406-4457-9b67-bc53641e6179', 'KASI', 'Kepala Seksi', 'Struktural', 50, true, '2026-07-27 11:52:49.259566+00', '2026-07-27 11:52:49.259566+00', NULL, false),
	('180eaafe-34bd-4d6a-b5da-d0c7d09d4af6', 'STAF', 'Staf', 'Pelaksana', 60, true, '2026-07-27 11:52:49.259566+00', '2026-07-27 11:52:49.259566+00', NULL, false),
	('0c0cdef2-9fe5-4dcc-aae7-91fcadf93b8e', 'OPERATOR', 'Operator', 'Pelaksana', 70, true, '2026-07-27 11:52:49.259566+00', '2026-07-27 11:52:49.259566+00', NULL, false),
	('1f1c231a-b19a-4c17-9dbe-17286d8f98b4', 'GURU', 'Guru', 'Fungsional', 80, true, '2026-07-27 11:52:49.259566+00', '2026-07-27 11:52:49.259566+00', NULL, false),
	('03d6401e-880b-4633-b0cb-f37b800795c5', 'TENAGA_TEKNIS', 'Tenaga Teknis', 'Fungsional', 90, true, '2026-07-27 11:52:49.259566+00', '2026-07-27 11:52:49.259566+00', NULL, false),
	('84bd3f38-798f-46ad-8c97-8c76960810c7', 'SYS_KEPALA_OPD', 'Kepala OPD', 'Struktural', 10, true, '2026-07-27 12:14:17.900329+00', '2026-07-27 13:02:15.673299+00', 'kepala_opd', true),
	('1c326c24-eec5-4b33-92ea-451053df15d6', 'SYS_SEKRETARIS', 'Sekretaris', 'Struktural', 20, true, '2026-07-27 12:14:17.900329+00', '2026-07-27 13:02:15.673299+00', 'sekretaris', true),
	('1df71ce8-4378-47e0-a298-3068f039da9d', 'SYS_KEPALA_BIDANG', 'Kepala Bidang', 'Struktural', 30, true, '2026-07-27 12:14:17.900329+00', '2026-07-27 13:02:15.673299+00', 'kepala_bidang', true),
	('5feae3f2-7050-4b58-aafb-84c399e84274', 'SYS_KEPALA_SEKOLAH', 'Kepala Sekolah', 'Struktural', 40, true, '2026-07-27 12:14:17.900329+00', '2026-07-27 13:02:15.673299+00', 'kepala_sekolah', true),
	('6d83828b-66a1-474a-b384-3fe0e5f9f730', 'SYS_OPERATOR', 'Operator', 'Fungsional', 50, true, '2026-07-27 12:14:17.900329+00', '2026-07-27 13:02:15.673299+00', 'operator', true),
	('0d8a807b-58cd-4850-9eac-6a9c7452056a', 'SYS_VERIFIKATOR', 'Verifikator', 'Fungsional', 60, true, '2026-07-27 12:14:17.900329+00', '2026-07-27 13:02:15.673299+00', 'verifikator', true),
	('f5f3860f-2926-49dc-a64a-2443626a93b9', 'SYS_STAFF', 'Staff', 'Pelaksana', 70, true, '2026-07-27 12:14:17.900329+00', '2026-07-27 13:02:15.673299+00', 'staff', true),
	('e0e83ce4-9ca6-4f1a-9d0c-1f39206d3264', 'SYS_GURU', 'Guru', 'Fungsional', 80, true, '2026-07-27 12:14:17.900329+00', '2026-07-27 13:02:15.673299+00', 'guru', true),
	('c93a42ef-5e09-45ea-bb99-e0f94c973c5c', 'SYS_TENAGA_TEKNIS', 'Tenaga Teknis', 'Fungsional', 90, true, '2026-07-27 12:14:17.900329+00', '2026-07-27 13:02:15.673299+00', 'tenaga_teknis', true),
	('98fa7afc-edf6-4578-84c7-fa6064aa369d', 'SYS_LAINNYA', 'Lainnya', 'Umum', 100, true, '2026-07-27 12:14:17.900329+00', '2026-07-27 13:02:15.673299+00', 'lainnya', true) ON CONFLICT DO NOTHING;


--
-- Data for Name: pejabat; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pejabat VALUES
	('756a6a3f-8f9c-4f65-aebb-71dd9e8d2352', 'Dr. H. Budi Santoso, M.Si.', 'Bupati', NULL, 1, true, '2026-07-27 23:34:50.929727+00', '2026-07-27 23:34:50.929727+00', NULL, 'bupati', true, NULL, '196501011990031001'),
	('a0b730c0-d469-4976-bdbc-606277ec9542', 'Ir. Hj. Sri Wahyuni, M.T.', 'Wakil Bupati', NULL, 2, true, '2026-07-27 23:34:50.929727+00', '2026-07-27 23:34:50.929727+00', NULL, 'wakil_bupati', true, NULL, '196707071992032002'),
	('244ad72b-cbb9-45f7-9f7e-ca4094b113c7', 'Drs. Ahmad Fauzi, M.M.', 'Sekretaris Daerah', NULL, 3, true, '2026-07-27 23:34:50.929727+00', '2026-07-27 23:34:50.929727+00', NULL, 'sekda', true, '11111111-1111-1111-1111-000000000001', '196803151993031003'),
	('51e392f6-aa33-45dd-a27f-fb16586db5d3', 'Dra. Siti Nurhaliza, M.Si.', 'Kepala Disdukcapil', NULL, 10, true, '2026-07-27 23:34:50.929727+00', '2026-07-27 23:34:50.929727+00', NULL, NULL, false, '11111111-1111-1111-1111-000000000002', '197001101995032004'),
	('9539b036-1d7a-4e33-8779-50fb515262d4', 'Ir. Eko Prasetyo, M.T.', 'Kepala DPMPTSP', NULL, 11, true, '2026-07-27 23:34:50.929727+00', '2026-07-27 23:34:50.929727+00', NULL, NULL, false, '11111111-1111-1111-1111-000000000003', '197203151998031005'),
	('26f0b5ba-2449-4fb5-b74d-79070594ae33', 'Drs. Rahmat Hidayat, M.M.', 'Kepala Dishub', NULL, 12, true, '2026-07-27 23:34:50.929727+00', '2026-07-27 23:34:50.929727+00', NULL, NULL, false, '11111111-1111-1111-1111-000000000004', '197104201997031006'),
	('d18a875a-8c4c-4080-94e4-c335b40ce310', 'dr. Lestari Wulandari, M.Kes.', 'Kepala Dinkes', NULL, 13, true, '2026-07-27 23:34:50.929727+00', '2026-07-27 23:34:50.929727+00', NULL, NULL, false, '11111111-1111-1111-1111-000000000005', '196908121996032007'),
	('45945a34-cbad-4531-8344-03e070747156', 'Drs. Hendra Wijaya, M.Pd.', 'Kepala Disdik', NULL, 14, true, '2026-07-27 23:34:50.929727+00', '2026-07-27 23:34:50.929727+00', NULL, NULL, false, '11111111-1111-1111-1111-000000000006', '196710051994031008'),
	('ee39722b-c615-4a10-b39a-668162967e88', 'Dra. Ratna Dewi, M.Si.', 'Kepala Dinsos', NULL, 15, true, '2026-07-27 23:34:50.929727+00', '2026-07-27 23:34:50.929727+00', NULL, NULL, false, '11111111-1111-1111-1111-000000000007', '197005151995032009'),
	('14db8714-f7b0-473c-95a0-afd182feaf6f', 'Drs. Agus Setiawan, M.M.', 'Kepala BKPSDM', NULL, 16, true, '2026-07-27 23:34:50.929727+00', '2026-07-27 23:34:50.929727+00', NULL, NULL, false, '11111111-1111-1111-1111-000000000008', '196812251994031010') ON CONFLICT DO NOTHING;


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.permissions VALUES
	('f617ef76-ee4a-4923-a408-0a402d72c329', 'can_create_form', 'Buat Formulir', 'Formulir', 'Membuat form baru', '2026-07-27 11:52:42.898341+00'),
	('43e5d6e0-51ff-4258-aa91-be8ce77fd7eb', 'digital_signature.view', 'Lihat Tanda Tangan Digital', 'digital_signature', 'Akses lihat modul TTD digital', '2026-07-27 11:58:53.890586+00'),
	('3ab77864-91af-41da-8d25-bb018c62aabc', 'digital_signature.create', 'Buat Dokumen Tanda Tangan', 'digital_signature', 'Buat / upload dokumen utk TTD', '2026-07-27 11:58:53.890586+00'),
	('56a87aaa-af24-4721-b5ee-8010783a430f', 'digital_signature.sign', 'Tandatangani Dokumen', 'digital_signature', 'Lakukan penandatanganan dokumen', '2026-07-27 11:58:53.890586+00'),
	('1bfce67c-4b2f-436c-91e8-4c98dc866641', 'digital_signature.verify', 'Verifikasi Dokumen', 'digital_signature', 'Verifikasi keaslian dokumen', '2026-07-27 11:58:53.890586+00'),
	('2c65e8bc-8316-4721-81d1-621e224ee2e1', 'digital_signature.revoke', 'Cabut Tanda Tangan', 'digital_signature', 'Cabut penandatanganan dokumen', '2026-07-27 11:58:53.890586+00'),
	('52873a2e-2812-4796-948a-33c4f34c8a07', 'digital_signature.admin', 'Admin Tanda Tangan Digital', 'digital_signature', 'Administrasi modul TTD digital', '2026-07-27 11:58:53.890586+00'),
	('c6edbe4e-42c5-4cf8-a76e-ca7fd306320e', 'can_edit_form', 'Ubah Formulir', 'Formulir', 'Mengubah form yang ada', '2026-07-27 11:52:42.898341+00'),
	('c99c8e20-e9eb-4ea4-8386-4e52bd1a87e8', 'can_publish_form', 'Publikasikan Formulir', 'Formulir', 'Menerbitkan form ke publik / target', '2026-07-27 11:52:42.898341+00'),
	('b0f23b19-6b14-447c-8535-87178f8d25bb', 'can_assign_form', 'Assign Formulir', 'Formulir', 'Menetapkan form ke user/OPD/desa', '2026-07-27 11:52:42.898341+00'),
	('c9717053-7160-47f6-a2a6-779720388c69', 'can_verify_submission', 'Verifikasi Submission', 'Verifikasi', 'Melakukan verifikasi pengajuan', '2026-07-27 11:52:42.898341+00'),
	('9a6b6d87-0f77-46f0-a7f2-888ac1da5bc7', 'can_approve_submission', 'Setujui Submission', 'Verifikasi', 'Menyetujui pengajuan', '2026-07-27 11:52:42.898341+00'),
	('3910c681-4194-4770-b0c6-50a178685895', 'view_all_reports', 'Lihat Semua Laporan', 'Pemda', 'Melihat laporan lintas OPD', '2026-07-27 11:52:42.898341+00'),
	('0b5d9fbe-506a-4c5c-a0c6-b9d337860e5a', 'view_all_performance', 'Lihat Semua Kinerja', 'Pemda', 'Melihat kinerja lintas OPD', '2026-07-27 11:52:42.898341+00'),
	('772e43a3-c7ce-42f9-8877-3880a4e1b5fa', 'view_all_surveys', 'Lihat Semua Survei', 'Pemda', 'Melihat survei lintas OPD', '2026-07-27 11:52:42.898341+00'),
	('5221fb6b-3fee-40b4-aecb-f93c4deaa501', 'view_kabupaten_dashboard', 'Dashboard Kabupaten', 'Pemda', 'Akses dashboard kabupaten', '2026-07-27 11:52:42.898341+00'),
	('4efe1397-bcf0-4251-bcd2-3e1eaac497d5', 'view_cross_opd_analytics', 'Analitik Lintas OPD', 'Pemda', 'Akses analitik lintas OPD', '2026-07-27 11:52:42.898341+00'),
	('22237c09-5866-4f46-8fe4-cae02d1cb77d', 'pemda.view', 'Pemda: Lihat', 'Pemda', 'Akses lihat modul Pemda', '2026-07-27 11:52:42.898341+00'),
	('7d5e76be-defc-42fd-94e6-110e0ead1850', 'pemda.manage', 'Pemda: Kelola', 'Pemda', 'Kelola konfigurasi Pemda', '2026-07-27 11:52:42.898341+00'),
	('84d4b568-18fb-40e4-ba47-3cc97349f81c', 'pemda.monitor', 'Pemda: Monitor', 'Pemda', 'Monitor operasional Pemda', '2026-07-27 11:52:42.898341+00'),
	('b409e900-66ec-4bdd-aa88-64db85300927', 'executive.view', 'Eksekutif: Lihat', 'Eksekutif', 'Akses dashboard eksekutif', '2026-07-27 11:52:42.898341+00'),
	('374104b3-c98f-4019-9ef5-e506b2bfdccb', 'executive.approve', 'Eksekutif: Setujui', 'Eksekutif', 'Persetujuan level eksekutif', '2026-07-27 11:52:42.898341+00'),
	('f0b84380-ffa3-46e3-881e-b313fe922dc4', 'executive.sign', 'Eksekutif: Tandatangani', 'Eksekutif', 'Tanda tangan level eksekutif', '2026-07-27 11:52:42.898341+00'),
	('74872a3d-2edf-48d2-b5f9-001c929a877a', 'can_manage_forms', 'Kelola Formulir', 'Formulir', 'Kelola penuh siklus form', '2026-07-27 11:52:42.898341+00'),
	('ccb1c23c-a53b-4ef9-8688-5f3fa719d15c', 'can_reject_submission', 'Tolak Submission', 'Verifikasi', 'Menolak pengajuan', '2026-07-27 11:52:42.898341+00'),
	('5ee6130b-6490-4464-a9f2-810c39939e1e', 'can_request_revision', 'Minta Revisi', 'Verifikasi', 'Meminta revisi pengajuan', '2026-07-27 11:52:42.898341+00'),
	('c2805f58-6aed-4871-b1ec-dc50fbd4c340', 'can_view_sensitive_document', 'Lihat Dokumen Sensitif', 'Dokumen', 'Membuka dokumen berklasifikasi', '2026-07-27 11:52:42.898341+00'),
	('48b89d1d-d09a-475a-93a3-4ddf12ab7fdc', 'can_download_document', 'Unduh Dokumen', 'Dokumen', 'Mengunduh dokumen', '2026-07-27 11:52:42.898341+00'),
	('b85a1633-cc18-4864-b183-e4a7f22cf18a', 'can_share_document', 'Bagikan Dokumen', 'Dokumen', 'Membagikan dokumen ke pihak lain', '2026-07-27 11:52:42.898341+00'),
	('fcc3e428-1b92-4971-82aa-aa230d517a68', 'can_request_document', 'Ajukan Dokumen', 'Dokumen', 'Mengajukan permintaan dokumen', '2026-07-27 11:52:42.898341+00'),
	('5e9414b8-c248-4d53-a36a-4769705f55e6', 'can_manage_users', 'Kelola User', 'Administrasi', 'Kelola akun pengguna', '2026-07-27 11:52:42.898341+00'),
	('1d41412e-a981-4b29-b9b7-ef4f2fa9d09e', 'can_manage_opd', 'Kelola OPD', 'Administrasi', 'Kelola master OPD', '2026-07-27 11:52:42.898341+00'),
	('242c3c09-499c-4ce1-8170-16519ef44e87', 'can_manage_roles', 'Kelola Role', 'Administrasi', 'Kelola pemberian role', '2026-07-27 11:52:42.898341+00'),
	('8e7772af-3ff9-4fb4-97a7-6106e57a10e8', 'can_view_audit_logs', 'Lihat Audit Log', 'Administrasi', 'Melihat log audit sistem', '2026-07-27 11:52:42.898341+00'),
	('adb7ff01-9ea5-4c8c-b654-10df3896b820', 'can_export_data', 'Ekspor Data', 'Administrasi', 'Mengekspor data ke file', '2026-07-27 11:52:42.898341+00'),
	('4d82e1cc-851d-4b22-afb1-815e2d7f318f', 'can_approve_registration', 'Setujui Registrasi', 'Administrasi', 'Menyetujui pendaftaran akun baru', '2026-07-27 11:52:42.898341+00'),
	('589c962e-8643-4f2d-95c4-880f6dd2f9da', 'can_request_data', 'Ajukan Permintaan Data', 'Data', 'Mengajukan permintaan dataset', '2026-07-27 11:52:42.898341+00'),
	('24b8bb1f-c131-4740-93ec-96618d744b96', 'can_approve_data_request', 'Setujui Permintaan Data', 'Data', 'Menyetujui permintaan dataset', '2026-07-27 11:52:42.898341+00'),
	('e5c04aca-87b4-4ef1-9cbb-ba09717edb34', 'view_all_opd', 'Lihat Semua OPD', 'Pemda', 'Melihat data lintas OPD', '2026-07-27 11:52:42.898341+00'),
	('984d10b1-a55b-452c-9695-90fbedb48ea7', 'executive.disposition', 'Eksekutif: Disposisi', 'Eksekutif', 'Membuat disposisi eksekutif', '2026-07-27 11:52:42.898341+00'),
	('f8f2a487-84ea-499a-b641-39a46ca26bca', 'view_executive_dashboard', 'Dashboard Eksekutif', 'Eksekutif', 'Akses dashboard eksekutif', '2026-07-27 11:52:42.898341+00'),
	('a3541d24-7cbd-4770-86d6-7a8aa4fa68d8', 'view_all_submissions', 'Lihat Semua Submission', 'Pemda', 'Melihat submission lintas OPD', '2026-07-27 11:52:42.898341+00'),
	('6c7ae74e-8bd1-498f-af2b-1f1e76dbd4a6', 'view_all_attendance', 'Lihat Semua Absensi', 'Pemda', 'Melihat absensi lintas OPD', '2026-07-27 11:52:42.898341+00'),
	('7566f053-e2ea-4fc4-ae8e-608461ff95c1', 'view_all_assets', 'Lihat Semua Aset', 'Pemda', 'Melihat aset lintas OPD', '2026-07-27 11:52:42.898341+00'),
	('4571102b-7262-4e47-aacc-523bec3d472e', 'view_all_datasets', 'Lihat Semua Dataset', 'Pemda', 'Melihat dataset lintas OPD', '2026-07-27 11:52:42.898341+00') ON CONFLICT DO NOTHING;


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.role_permissions VALUES
	('pemda.view', '2026-07-27 12:14:29.481997+00'),
	('pemda.manage', '2026-07-27 12:14:29.481997+00'),
	('pemda.monitor', '2026-07-27 12:14:29.481997+00'),
	('view_all_opd', '2026-07-27 12:14:29.481997+00'),
	('view_all_submissions', '2026-07-27 12:14:29.481997+00'),
	('view_all_attendance', '2026-07-27 12:14:29.481997+00'),
	('view_all_assets', '2026-07-27 12:14:29.481997+00'),
	('view_all_datasets', '2026-07-27 12:14:29.481997+00'),
	('view_all_reports', '2026-07-27 12:14:29.481997+00'),
	('view_all_performance', '2026-07-27 12:14:29.481997+00'),
	('view_all_surveys', '2026-07-27 12:14:29.481997+00'),
	('view_kabupaten_dashboard', '2026-07-27 12:14:29.481997+00'),
	('view_cross_opd_analytics', '2026-07-27 12:14:29.481997+00'),
	('can_manage_users', '2026-07-27 12:14:29.481997+00'),
	('can_manage_opd', '2026-07-27 12:14:29.481997+00'),
	('can_manage_roles', '2026-07-27 12:14:29.481997+00'),
	('can_view_audit_logs', '2026-07-27 12:14:29.481997+00'),
	('can_export_data', '2026-07-27 12:14:29.481997+00'),
	('can_approve_registration', '2026-07-27 12:14:29.481997+00'),
	('executive.view', '2026-07-27 12:14:29.481997+00'),
	('executive.view', '2026-07-27 12:14:29.481997+00'),
	('view_executive_dashboard', '2026-07-27 12:14:29.481997+00'),
	('view_kabupaten_dashboard', '2026-07-27 12:14:29.481997+00'),
	('view_all_opd', '2026-07-27 12:14:29.481997+00'),
	('view_all_submissions', '2026-07-27 12:14:29.481997+00'),
	('view_all_attendance', '2026-07-27 12:14:29.481997+00'),
	('view_all_assets', '2026-07-27 12:14:29.481997+00'),
	('view_all_datasets', '2026-07-27 12:14:29.481997+00'),
	('view_all_reports', '2026-07-27 12:14:29.481997+00'),
	('view_all_performance', '2026-07-27 12:14:29.481997+00'),
	('view_all_surveys', '2026-07-27 12:14:29.481997+00'),
	('can_create_form', '2026-07-27 12:14:29.481997+00'),
	('can_edit_form', '2026-07-27 12:14:29.481997+00'),
	('can_publish_form', '2026-07-27 12:14:29.481997+00'),
	('can_assign_form', '2026-07-27 12:14:29.481997+00'),
	('can_manage_forms', '2026-07-27 12:14:29.481997+00'),
	('can_verify_submission', '2026-07-27 12:14:29.481997+00'),
	('can_approve_submission', '2026-07-27 12:14:29.481997+00'),
	('can_reject_submission', '2026-07-27 12:14:29.481997+00'),
	('can_request_revision', '2026-07-27 12:14:29.481997+00'),
	('can_view_sensitive_document', '2026-07-27 12:14:29.481997+00'),
	('can_download_document', '2026-07-27 12:14:29.481997+00'),
	('can_share_document', '2026-07-27 12:14:29.481997+00'),
	('can_approve_data_request', '2026-07-27 12:14:29.481997+00'),
	('can_export_data', '2026-07-27 12:14:29.481997+00'),
	('can_verify_submission', '2026-07-27 12:14:29.481997+00'),
	('can_request_revision', '2026-07-27 12:14:29.481997+00'),
	('can_download_document', '2026-07-27 12:14:29.481997+00'),
	('can_request_document', '2026-07-27 12:14:29.481997+00'),
	('can_download_document', '2026-07-27 12:14:29.481997+00'),
	('can_request_document', '2026-07-27 12:14:29.481997+00') ON CONFLICT DO NOTHING;


--
-- PostgreSQL database dump complete
--

\unrestrict Mxuxr1t2BfohDvBvecsRNgYWVNs4vGCtBn0efQRfXUgachC48SNWthp3OSDy6tE


--
-- Storage buckets (idempotent). Semua privat: akses via RLS storage.objects + signed URL.
--
INSERT INTO storage.buckets (id, name, public) VALUES
  ('pejabat-foto','pejabat-foto',false),
  ('branding','branding',false),
  ('berkas-permohonan','berkas-permohonan',false),
  ('aset-foto','aset-foto',false),
  ('form-submissions','form-submissions',false),
  ('signed-documents','signed-documents',false),
  ('signatures','signatures',false),
  ('share-files','share-files',false),
  ('absensi-foto','absensi-foto',false),
  ('verification-assets','verification-assets',false),
  ('documents','documents',false),
  ('bukti-dokumen','bukti-dokumen',false),
  ('form-uploads','form-uploads',false),
  ('document-templates','document-templates',false)
ON CONFLICT (id) DO NOTHING;

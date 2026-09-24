// Template default per jenis bukti — dapat di-override lewat
// `public.bukti_template_override` per OPD via admin UI (Phase 2B).
export type BuktiKind = "permohonan" | "aset" | "izin_asn";

const permohonanHtml = `
<h2 style="text-align:center">BUKTI PERMOHONAN LAYANAN PUBLIK</h2>
<p>Dokumen ini adalah bukti resmi pengajuan permohonan layanan publik. Tunjukkan bukti ini beserta identitas diri (KTP) saat mengambil dokumen di OPD terkait.</p>
<p><b>Nomor Bukti:</b> {{bukti.nomor}}<br>
<b>Kode Permohonan:</b> {{permohonan.kode}}<br>
<b>Judul:</b> {{permohonan.judul}}<br>
<b>Kategori Layanan:</b> {{permohonan.kategori}}<br>
<b>Tanggal Pengajuan:</b> {{permohonan.tanggal_masuk}}</p>
<p><b>Pemohon:</b> {{pemohon.nama}}<br>
<b>NIK:</b> {{pemohon.nik}}<br>
<b>No HP:</b> {{pemohon.no_hp}}<br>
<b>Alamat:</b> {{pemohon.alamat}}, Desa {{pemohon.desa}}</p>
<p><b>OPD Tujuan:</b> {{opd.nama}} ({{opd.singkatan}})</p>
<p style="margin-top:24px">Verifikasi keaslian bukti ini dengan memindai kode QR di bawah. Petugas OPD wajib melakukan verifikasi QR sebelum menyerahkan dokumen fisik.</p>
<p style="text-align:center">{{sistem.qr_code}}</p>
<p style="text-align:center"><b>Scan QR untuk verifikasi</b></p>
`.trim();

const asetHtml = `
<h2 style="text-align:center">SURAT KETERANGAN ASET / BARANG MILIK DAERAH</h2>
<p>Dokumen ini menerangkan data resmi barang milik daerah sebagaimana terdaftar pada sistem manajemen aset.</p>
<p><b>Nomor:</b> {{bukti.nomor}}<br>
<b>Kode Aset:</b> {{aset.kode}}<br>
<b>Nama Barang:</b> {{aset.nama}}<br>
<b>Kategori:</b> {{aset.kategori}}<br>
<b>Kondisi:</b> {{aset.kondisi}}<br>
<b>Merk/Seri:</b> {{aset.merk}} / {{aset.nomor_seri}}<br>
<b>Lokasi:</b> {{aset.lokasi}}<br>
<b>Nilai Perolehan:</b> Rp {{aset.nilai_perolehan}}<br>
<b>Tanggal Perolehan:</b> {{aset.tanggal_perolehan}}</p>
<p><b>Pemegang:</b> {{pemegang.nama}} ({{pemegang.nip}})<br>
<b>OPD:</b> {{opd.nama}} ({{opd.singkatan}})</p>
<p style="margin-top:24px">Ditandatangani secara digital oleh:</p>
<p><b>{{signer.nama}}</b><br>{{signer.jabatan}}<br>NIP. {{signer.nip}}</p>
<p style="margin-top:16px">Verifikasi keaslian dengan memindai QR di bawah:</p>
<p style="text-align:center">{{sistem.qr_code}}</p>
`.trim();

const izinAsnHtml = `
<h2 style="text-align:center">SURAT KEPUTUSAN IZIN / CUTI ASN</h2>
<p>Berdasarkan pengajuan yang telah disetujui, dengan ini diberikan izin kepada:</p>
<p><b>Nama:</b> {{asn.nama}}<br>
<b>NIP:</b> {{asn.nip}}<br>
<b>Jabatan:</b> {{asn.jabatan}}<br>
<b>OPD:</b> {{opd.nama}} ({{opd.singkatan}})</p>
<p><b>Nomor:</b> {{bukti.nomor}}<br>
<b>Jenis Izin:</b> {{izin.jenis}}<br>
<b>Periode:</b> {{izin.dari}} s.d. {{izin.sampai}}<br>
<b>Alasan:</b> {{izin.alasan}}</p>
<p style="margin-top:16px">{{izin.catatan_approval}}</p>
<p style="margin-top:24px">Ditetapkan oleh:</p>
<p><b>{{signer.nama}}</b><br>{{signer.jabatan}}<br>NIP. {{signer.nip}}</p>
<p style="margin-top:16px">Verifikasi keaslian dengan memindai QR di bawah:</p>
<p style="text-align:center">{{sistem.qr_code}}</p>
`.trim();

export function defaultTemplateHtml(kind: BuktiKind): string {
  if (kind === "aset") return asetHtml;
  if (kind === "izin_asn") return izinAsnHtml;
  return permohonanHtml;
}
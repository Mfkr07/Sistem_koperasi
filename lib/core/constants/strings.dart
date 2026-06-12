class AppStrings {
  static const String appTitle = 'TPK Koperasi Sawit';
  static const String dashboard = 'Dashboard';
  static const String sesiTimbang = 'Sesi Timbang';
  static const String dataAnggota = 'Data Anggota';
  static const String pinjaman = 'Pinjaman Anggota';
  static const String laporan = 'Laporan & Rekap';
  static const String pengaturan = 'Pengaturan';
  
  // Sesi
  static const String bukaSesiBaru = 'Buka Sesi Baru';
  static const String tutupSesi = 'Tutup Sesi & Rekap';
  static const String pilihKoordinator = 'Pilih Koordinator';
  static const String hargaPerKg = 'Harga per Kg';
  static const String tarifAdm = 'Tarif ADM per Kg';
  static const String tarifTrsDusun = 'Tarif TRS Dusun per Kg';
  static const String tarifTrsIbol = 'Tarif TRS Ibol per Kg';
  static const String catatanSesi = 'Catatan Sesi (Opsional)';
  static const String bukaSesiSuccess = 'Sesi timbang baru berhasil dibuka.';
  static const String tutupSesiSuccess = 'Sesi timbang berhasil ditutup. Database di-backup otomatis.';
  
  // Timbangan / Transaksi
  static const String inputTimbangan = 'Input Timbangan';
  static const String namaAnggota = 'Nama Anggota / Petani';
  static const String cariAnggota = 'Cari Anggota...';
  static const String beratKg = 'Berat Hasil Timbangan (Kg)';
  static const String tipeAngkutan = 'Jenis Angkutan';
  static const String potongPinjaman = 'Potongan Pinjaman';
  static const String previewKalkulasi = 'Preview Kalkulasi';
  static const String hargaBruto = 'Harga Bruto';
  static const String biayaAdm = 'Biaya ADM';
  static const String biayaTrs = 'Biaya TRS';
  static const String totalPotongan = 'Total Potongan';
  static const String jumlahDisetor = 'Jumlah Disetor';
  static const String simpanTransaksi = 'Simpan Transaksi';
  static const String kepemilikanBersama = 'Kepemilikan Bersama';
  static const String porsiPemilik = 'Pembagian Porsi Persentase';
  static const String voidTransaksi = 'Batalkan Transaksi (Void)';
  
  // Pinjaman
  static const String tambahPinjaman = 'Tambah Pinjaman Baru';
  static const String jumlahPinjaman = 'Jumlah Pokok Pinjaman';
  static const String keteranganPinjaman = 'Keterangan Pinjaman';
  static const String historiPinjaman = 'Histori Pinjaman';
  static const String saldoSisa = 'Sisa Saldo';
  static const String statusLunas = 'LUNAS';
  static const String statusAktif = 'AKTIF';
  
  // Anggota
  static const String tambahAnggota = 'Tambah Anggota Baru';
  static const String editAnggota = 'Edit Data Anggota';
  static const String noHp = 'Nomor HP (Opsional)';
  static const String statusAktifLabel = 'Status Aktif';
  
  // Laporan
  static const String rekapHarian = 'Rekap Harian';
  static const String laporanPerAnggota = 'Laporan per Anggota';
  static const String laporanHutang = 'Laporan Pinjaman';
  static const String rekapGlobal = 'Rekap Global Multi-Sesi';
  static const String exportExcel = 'Ekspor ke Excel';
  static const String exportPdf = 'Ekspor ke PDF';
  static const String backupManual = 'Backup Database';
  static const String restoreManual = 'Restore Database';
  
  // Validations & Errors
  static const String errBeratNol = 'Berat tidak boleh nol';
  static const String errBeratNegatif = 'Berat tidak valid';
  static const String errBeratBukanAngka = 'Masukkan angka yang valid';
  static const String errPinjamanLebih = 'Nominal potong melebihi saldo aktif';
  static const String errSetorNegatif = 'Potongan melebihi nilai kotor sawit';
  static const String errPorsi100 = 'Total porsi persentase harus tepat 100%';
  static const String errPilihPemilik2 = 'Pilih pemilik kedua';
  static const String errSesiTanggalSama = 'Sesi untuk tanggal ini sudah ada';
  static const String errTidakAdaSesiBuka = 'Tidak ada sesi aktif';
}

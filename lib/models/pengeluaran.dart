class Pengeluaran {
  final String pengeluaranId;
  final String sesiId;
  final String kategori; // KUD / TENAGA_KERJA / TRUCK / JAGA_MALAM / KAS / LAIN
  final String? namaPenerima;
  final int jumlah;
  final String? keterangan;
  final String createdAt;

  Pengeluaran({
    required this.pengeluaranId,
    required this.sesiId,
    required this.kategori,
    this.namaPenerima,
    required this.jumlah,
    this.keterangan,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'pengeluaran_id': pengeluaranId,
      'sesi_id': sesiId,
      'kategori': kategori,
      'nama_penerima': namaPenerima,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'created_at': createdAt,
    };
  }

  factory Pengeluaran.fromMap(Map<String, dynamic> map) {
    return Pengeluaran(
      pengeluaranId: map['pengeluaran_id'] as String,
      sesiId: map['sesi_id'] as String,
      kategori: map['kategori'] as String,
      namaPenerima: map['nama_penerima'] as String?,
      jumlah: map['jumlah'] as int,
      keterangan: map['keterangan'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}

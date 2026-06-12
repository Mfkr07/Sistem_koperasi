class Pinjaman {
  final String pinjamanId;
  final String anggotaId;
  final String tanggalPinjam;
  final int jumlahPokok;
  final int saldoSisa;
  final String status; // AKTIF / LUNAS
  final String? keterangan;
  final String createdAt;

  Pinjaman({
    required this.pinjamanId,
    required this.anggotaId,
    required this.tanggalPinjam,
    required this.jumlahPokok,
    required this.saldoSisa,
    required this.status,
    this.keterangan,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'pinjaman_id': pinjamanId,
      'anggota_id': anggotaId,
      'tanggal_pinjam': tanggalPinjam,
      'jumlah_pokok': jumlahPokok,
      'saldo_sisa': saldoSisa,
      'status': status,
      'keterangan': keterangan,
      'created_at': createdAt,
    };
  }

  factory Pinjaman.fromMap(Map<String, dynamic> map) {
    return Pinjaman(
      pinjamanId: map['pinjaman_id'] as String,
      anggotaId: map['anggota_id'] as String,
      tanggalPinjam: map['tanggal_pinjam'] as String,
      jumlahPokok: map['jumlah_pokok'] as int,
      saldoSisa: map['saldo_sisa'] as int,
      status: map['status'] as String,
      keterangan: map['keterangan'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}

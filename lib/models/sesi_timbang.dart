class SesiTimbang {
  final String sesiId;
  final String koordinatorId;
  final String tanggal; // YYYY-MM-DD
  final int hargaPerKg;
  final int tarifAdmPerKg;
  final int tarifTrsDusun;
  final int tarifTrsIbol;
  final String status; // BUKA / TUTUP
  final String? catatan;
  final String createdAt;
  final String? closedAt;

  SesiTimbang({
    required this.sesiId,
    required this.koordinatorId,
    required this.tanggal,
    required this.hargaPerKg,
    required this.tarifAdmPerKg,
    required this.tarifTrsDusun,
    required this.tarifTrsIbol,
    required this.status,
    this.catatan,
    required this.createdAt,
    this.closedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'sesi_id': sesiId,
      'koordinator_id': koordinatorId,
      'tanggal': tanggal,
      'harga_per_kg': hargaPerKg,
      'tarif_adm_per_kg': tarifAdmPerKg,
      'tarif_trs_dusun': tarifTrsDusun,
      'tarif_trs_ibol': tarifTrsIbol,
      'status': status,
      'catatan': catatan,
      'created_at': createdAt,
      'closed_at': closedAt,
    };
  }

  factory SesiTimbang.fromMap(Map<String, dynamic> map) {
    return SesiTimbang(
      sesiId: map['sesi_id'] as String,
      koordinatorId: map['koordinator_id'] as String,
      tanggal: map['tanggal'] as String,
      hargaPerKg: map['harga_per_kg'] as int,
      tarifAdmPerKg: map['tarif_adm_per_kg'] as int,
      tarifTrsDusun: map['tarif_trs_dusun'] as int,
      tarifTrsIbol: map['tarif_trs_ibol'] as int,
      status: map['status'] as String,
      catatan: map['catatan'] as String?,
      createdAt: map['created_at'] as String,
      closedAt: map['closed_at'] as String?,
    );
  }
}

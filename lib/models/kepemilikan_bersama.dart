class KepemilikanBersama {
  final int? id;
  final String transaksiId;
  final String anggotaId;
  final double porsiPersen;
  final String? catatan; // e.g. Owner name

  KepemilikanBersama({
    this.id,
    required this.transaksiId,
    required this.anggotaId,
    required this.porsiPersen,
    this.catatan,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'transaksi_id': transaksiId,
      'anggota_id': anggotaId,
      'porsi_persen': porsiPersen,
      'catatan': catatan,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory KepemilikanBersama.fromMap(Map<String, dynamic> map) {
    return KepemilikanBersama(
      id: map['id'] as int?,
      transaksiId: map['transaksi_id'] as String,
      anggotaId: map['anggota_id'] as String,
      porsiPersen: (map['porsi_persen'] as num).toDouble(),
      catatan: map['catatan'] as String?,
    );
  }
}

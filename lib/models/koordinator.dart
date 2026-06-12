class Koordinator {
  final String koordinatorId;
  final String nama;
  final String? catatan;
  final String createdAt;

  Koordinator({
    required this.koordinatorId,
    required this.nama,
    this.catatan,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'koordinator_id': koordinatorId,
      'nama': nama,
      'catatan': catatan,
      'created_at': createdAt,
    };
  }

  factory Koordinator.fromMap(Map<String, dynamic> map) {
    return Koordinator(
      koordinatorId: map['koordinator_id'] as String,
      nama: map['nama'] as String,
      catatan: map['catatan'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}

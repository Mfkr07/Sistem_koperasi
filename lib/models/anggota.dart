class Anggota {
  final String anggotaId;
  final String koordinatorId;
  final String nama;
  final String tipeAngkutan; // SENDIRI / DUSUN / IBOL
  final String? noHp;
  final int statusAktif; // 1 = aktif, 0 = nonaktif
  final int tarifTransport; // Rp per Kg (individual transport rate)
  final String createdAt;

  Anggota({
    required this.anggotaId,
    required this.koordinatorId,
    required this.nama,
    required this.tipeAngkutan,
    this.noHp,
    this.statusAktif = 1,
    this.tarifTransport = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'anggota_id': anggotaId,
      'koordinator_id': koordinatorId,
      'nama': nama,
      'tipe_angkutan': tipeAngkutan,
      'no_hp': noHp,
      'status_aktif': statusAktif,
      'tarif_transport': tarifTransport,
      'created_at': createdAt,
    };
  }

  factory Anggota.fromMap(Map<String, dynamic> map) {
    return Anggota(
      anggotaId: map['anggota_id'] as String,
      koordinatorId: map['koordinator_id'] as String,
      nama: map['nama'] as String,
      tipeAngkutan: map['tipe_angkutan'] as String,
      noHp: map['no_hp'] as String?,
      statusAktif: map['status_aktif'] as int,
      tarifTransport: (map['tarif_transport'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] as String,
    );
  }
}

class Transaksi {
  final String transaksiId;
  final String sesiId;
  final String anggotaId;
  final int beratKg;
  final int pinjamanDipotong;
  final String noStruk;
  final int sudahCetak; // 0 = belum, 1 = sudah
  final String? waktuCetak;
  final String waktuInput;
  final int isVoid; // 0 = valid, 1 = void

  Transaksi({
    required this.transaksiId,
    required this.sesiId,
    required this.anggotaId,
    required this.beratKg,
    this.pinjamanDipotong = 0,
    required this.noStruk,
    this.sudahCetak = 0,
    this.waktuCetak,
    required this.waktuInput,
    this.isVoid = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'transaksi_id': transaksiId,
      'sesi_id': sesiId,
      'anggota_id': anggotaId,
      'berat_kg': beratKg,
      'pinjaman_dipotong': pinjamanDipotong,
      'no_struk': noStruk,
      'sudah_cetak': sudahCetak,
      'waktu_cetak': waktuCetak,
      'waktu_input': waktuInput,
      'is_void': isVoid,
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      transaksiId: map['transaksi_id'] as String,
      sesiId: map['sesi_id'] as String,
      anggotaId: map['anggota_id'] as String,
      beratKg: map['berat_kg'] as int,
      pinjamanDipotong: map['pinjaman_dipotong'] as int,
      noStruk: map['no_struk'] as String,
      sudahCetak: map['sudah_cetak'] as int,
      waktuCetak: map['waktu_cetak'] as String?,
      waktuInput: map['waktu_input'] as String,
      isVoid: map['is_void'] as int,
    );
  }
}

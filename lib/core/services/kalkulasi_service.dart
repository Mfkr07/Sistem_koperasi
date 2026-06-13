class KalkulasiResult {
  final int beratTotal;
  final double porsiPersen;
  final int beratPorsi;
  final int hargaPerKg;
  final int hargaBruto;
  final int biayaAdm;
  final int biayaTrs;
  final int pinjamanDipotong;
  final int totalPotongan;
  final int jumlahDisetor;

  KalkulasiResult({
    required this.beratTotal,
    required this.porsiPersen,
    required this.beratPorsi,
    required this.hargaPerKg,
    required this.hargaBruto,
    required this.biayaAdm,
    required this.biayaTrs,
    required this.pinjamanDipotong,
    required this.totalPotongan,
    required this.jumlahDisetor,
  });
}

class KalkulasiService {
  /// Calculate transaction totals for a single member or one portion of a joint ownership.
  ///
  /// For joint ownership, [beratPorsi] can be calculated using [hitungBeratPorsi]
  /// to ensure the sum of parts exactly matches the total weight.
  static KalkulasiResult hitung({
    required int beratTotal,
    required double porsiPersen,
    required int hargaPerKg,
    required int tarifAdm,
    required int tarifTransport,
    required int pinjamanDipotong,
    int? customBeratPorsi,
  }) {
    // Determine the weight portion
    int beratPorsi = customBeratPorsi ?? (beratTotal * (porsiPersen / 100.0)).round();

    // Bruto
    int hargaBruto = beratPorsi * hargaPerKg;

    // ADM
    int biayaAdm = beratPorsi * tarifAdm;

    // TRS
    int biayaTrs = beratPorsi * tarifTransport;

    // Total Potongan
    int totalPotongan = biayaAdm + biayaTrs + pinjamanDipotong;

    // Net Amount paid to member
    int jumlahDisetor = hargaBruto - totalPotongan;

    return KalkulasiResult(
      beratTotal: beratTotal,
      porsiPersen: porsiPersen,
      beratPorsi: beratPorsi,
      hargaPerKg: hargaPerKg,
      hargaBruto: hargaBruto,
      biayaAdm: biayaAdm,
      biayaTrs: biayaTrs,
      pinjamanDipotong: pinjamanDipotong,
      totalPotongan: totalPotongan,
      jumlahDisetor: jumlahDisetor,
    );
  }

  /// Calculates the weight portions for two owners ensuring no fractional loss.
  static List<int> hitungBeratPorsiBersama(int beratTotal, double porsi1, double porsi2) {
    int part1 = (beratTotal * (porsi1 / 100.0)).round();
    int part2 = beratTotal - part1;
    return [part1, part2];
  }
}

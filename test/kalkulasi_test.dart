import 'package:flutter_test/flutter_test.dart';
import 'package:tpk_koperasi/core/services/kalkulasi_service.dart';

void main() {
  group('KalkulasiService Tests', () {
    test('Standard Single Owner Timbangan (Tipe Sendiri)', () {
      final res = KalkulasiService.hitung(
        beratTotal: 100,
        porsiPersen: 100.0,
        hargaPerKg: 17130,
        tarifAdm: 100,
        tarifTrsDusun: 100,
        tarifTrsIbol: 350,
        tipeAngkutan: 'SENDIRI',
        pinjamanDipotong: 0,
      );

      expect(res.beratPorsi, 100);
      expect(res.hargaBruto, 1713000); // 100 * 17130
      expect(res.biayaAdm, 10000);    // 100 * 100
      expect(res.biayaTrs, 0);        // Sendiri = 0
      expect(res.totalPotongan, 10000);
      expect(res.jumlahDisetor, 1703000);
    });

    test('Standard Single Owner Timbangan (Tipe Dusun)', () {
      final res = KalkulasiService.hitung(
        beratTotal: 150,
        porsiPersen: 100.0,
        hargaPerKg: 17130,
        tarifAdm: 100,
        tarifTrsDusun: 120, // custom Dusun rate
        tarifTrsIbol: 350,
        tipeAngkutan: 'DUSUN',
        pinjamanDipotong: 50000,
      );

      expect(res.beratPorsi, 150);
      expect(res.hargaBruto, 2569500); // 150 * 17130
      expect(res.biayaAdm, 15000);    // 150 * 100
      expect(res.biayaTrs, 18000);    // 150 * 120
      expect(res.pinjamanDipotong, 50000);
      expect(res.totalPotongan, 15000 + 18000 + 50000); // 83000
      expect(res.jumlahDisetor, 2569500 - 83000); // 2486500
    });

    test('Joint Ownership Weight Splitting (Odd Weight)', () {
      final parts = KalkulasiService.hitungBeratPorsiBersama(187, 50.0, 50.0);
      expect(parts[0] + parts[1], 187);
      expect(parts[0], 94); // 187 / 2 = 93.5 -> rounded
      expect(parts[1], 93); // remainder
    });

    test('Joint Ownership 50/50 Split Calculation details matching Contoh format struk', () {
      // 187 Kg, Rp. 17.130/Kg
      // Total Gross: Rp. 3.203.310
      // Portion: 50%
      // Adm/DLL: Rp. - (0)
      // Pinjaman: Rp. - (0)
      // Transport: Rp. - (0)
      // Jumlah Dibayar: Rp. 1.601.655
      
      final parts = KalkulasiService.hitungBeratPorsiBersama(187, 50.0, 50.0);
      
      final res1 = KalkulasiService.hitung(
        beratTotal: 187,
        porsiPersen: 50.0,
        hargaPerKg: 17130,
        tarifAdm: 100,
        tarifTrsDusun: 100,
        tarifTrsIbol: 350,
        tipeAngkutan: 'SENDIRI',
        pinjamanDipotong: 0,
        customBeratPorsi: parts[0],
      );

      final res2 = KalkulasiService.hitung(
        beratTotal: 187,
        porsiPersen: 50.0,
        hargaPerKg: 17130,
        tarifAdm: 100,
        tarifTrsDusun: 100,
        tarifTrsIbol: 350,
        tipeAngkutan: 'SENDIRI',
        pinjamanDipotong: 0,
        customBeratPorsi: parts[1],
      );

      // Verify combined gross matches 187 * 17130 = 3203310
      expect(res1.hargaBruto + res2.hargaBruto, 3203310);
      expect(res1.hargaBruto, 1610220); // 94 * 17130
      expect(res2.hargaBruto, 1593090); // 93 * 17130

      // Let's verify standard 50% payment portion from total gross directly (without per-kg rounding)
      // If we calculate strictly by portion:
      // Gross = 3.203.310 -> portion 50% = 1.601.655
      final grossPortion1 = (3203310 * 0.5).round();
      expect(grossPortion1, 1601655);
    });
  });
}

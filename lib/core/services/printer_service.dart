import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/kalkulasi_service.dart';

class PrinterService {
  static String formatCurrency(num value) {
    if (value == 0) return 'Rp. -';
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
    return formatter.format(value).trim();
  }

  /// Generate a plain text representation of the receipt (65 characters wide)
  static String generateTextReceipt({
    required String namaAnggota,
    required int beratTotal,
    required double porsiPersen,
    required int beratPorsi,
    required int hargaPerKg,
    required int hargaBruto,
    required int biayaAdm,
    required int biayaTrs,
    required int pinjamanDipotong,
    required int totalPotongan,
    required int jumlahDibayar,
    required String tanggalSesi, // YYYY-MM-DD
    required String noStruk,
    required String tipeAngkutan,
    required int tarifAdm,
  }) {
    final dateParts = tanggalSesi.split('-');
    String formattedDate = tanggalSesi;
    if (dateParts.length == 3) {
      // Convert to DD/M YYYY e.g. 12/5 2026
      int day = int.parse(dateParts[2]);
      int month = int.parse(dateParts[1]);
      String year = dateParts[0];
      formattedDate = '$day/$month $year';
    }

    final buffer = StringBuffer();
    const divider = '=================================================================';

    buffer.writeln(divider);
    buffer.writeln(_centerText('KOPERASI UNIT DESA', 65));
    buffer.writeln(_centerText('BERKAT', 65));
    buffer.writeln(_centerText('Badan Hukum No. 00292/BH/PAD KWK 6/VI/1996 Tgl. 3 Juli 1996', 65));
    buffer.writeln(_centerText('TPK Muara Ujanmas', 65));
    buffer.writeln(divider);
    buffer.writeln();
    buffer.writeln(_centerText('Tanda Terima', 65));
    buffer.writeln(_centerText('------------', 65));
    buffer.writeln();

    buffer.writeln(_leftRightAlign('Nama', ': $namaAnggota', 65));
    buffer.writeln(_leftRightAlign('Jumlah Timbangan', ': $beratTotal Kg', 65));
    buffer.writeln(_leftRightAlign('Harga per Kg', ': ${formatCurrency(hargaPerKg)}', 65));
    
    // For joint ownership, show the fractional division e.g. Rp. 3.203.310 / 2
    String kotorLabel = formatCurrency(hargaBruto);
    if (porsiPersen < 100.0) {
      int factor = (100 / porsiPersen).round();
      kotorLabel = '$kotorLabel / $factor';
    }
    buffer.writeln(_leftRightAlign('Jumlah Kotor', ': $kotorLabel', 65));
    buffer.writeln();

    buffer.writeln('Potongan :');
    buffer.writeln(_leftRightAlign('- Adm/DLL. $tarifAdm/Kg', ': ${formatCurrency(biayaAdm)}', 65));
    buffer.writeln(_leftRightAlign('- Pinjaman', ': ${formatCurrency(pinjamanDipotong)}', 65));
    
    String angkutLabel = '- Ongkos Angkut';
    if (tipeAngkutan.toUpperCase() != 'SENDIRI') {
      angkutLabel = '$angkutLabel (${tipeAngkutan.toUpperCase()})';
    }
    buffer.writeln(_leftRightAlign(angkutLabel, ': ${formatCurrency(biayaTrs)}', 65));
    buffer.writeln();

    buffer.writeln(_leftRightAlign('Jumlah Potongan', ': ${formatCurrency(totalPotongan)}', 65));
    buffer.writeln(_leftRightAlign('Jumlah Dibayar', ': ${formatCurrency(jumlahDibayar)}', 65));
    buffer.writeln();

    buffer.writeln(_centerText('Ujan Mas Lama, $formattedDate', 65, alignRight: true));
    buffer.writeln(_centerText('Bendahara', 65, alignRight: true));
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln(_centerText('(                      )', 65, alignRight: true));
    buffer.writeln(divider);

    return buffer.toString();
  }

  /// Print the receipt to a physical or virtual printer as a PDF layout
  static Future<void> printReceiptPdf({
    required String namaAnggota,
    required int beratTotal,
    required double porsiPersen,
    required int beratPorsi,
    required int hargaPerKg,
    required int hargaBruto,
    required int biayaAdm,
    required int biayaTrs,
    required int pinjamanDipotong,
    required int totalPotongan,
    required int jumlahDibayar,
    required String tanggalSesi,
    required String noStruk,
    required String tipeAngkutan,
    required int tarifAdm,
  }) async {
    final pdf = pw.Document();

    final textRepresentation = generateTextReceipt(
      namaAnggota: namaAnggota,
      beratTotal: beratTotal,
      porsiPersen: porsiPersen,
      beratPorsi: beratPorsi,
      hargaPerKg: hargaPerKg,
      hargaBruto: hargaBruto,
      biayaAdm: biayaAdm,
      biayaTrs: biayaTrs,
      pinjamanDipotong: pinjamanDipotong,
      totalPotongan: totalPotongan,
      jumlahDibayar: jumlahDibayar,
      tanggalSesi: tanggalSesi,
      noStruk: noStruk,
      tipeAngkutan: tipeAngkutan,
      tarifAdm: tarifAdm,
    );

    // Create a 80mm roll size PDF document
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 200 * PdfPageFormat.mm, marginAll: 5 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Text(
            textRepresentation,
            style: pw.TextStyle(
              font: pw.Font.courier(),
              fontSize: 7.5,
              lineSpacing: 1.2,
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Struk-$noStruk',
    );
  }

  /// Generate plain text receipt for payout
  static String generatePayoutTextReceipt({
    required String namaAnggota,
    required String anggotaId,
    required String tanggalPayout,
    required String payoutId,
    required List<Map<String, dynamic>> weighings,
    required int totalBerat,
    required int totalBruto,
    required int totalAdm,
    required int totalTrs,
    required int pinjamanDipotong,
    required int totalNetto,
  }) {
    final buffer = StringBuffer();
    const divider = '=================================================================';

    buffer.writeln(divider);
    buffer.writeln(_centerText('KOPERASI UNIT DESA', 65));
    buffer.writeln(_centerText('BERKAT', 65));
    buffer.writeln(_centerText('Badan Hukum No. 00292/BH/PAD KWK 6/VI/1996 Tgl. 3 Juli 1996', 65));
    buffer.writeln(_centerText('TPK Muara Ujanmas', 65));
    buffer.writeln(divider);
    buffer.writeln();
    buffer.writeln(_centerText('Struk Pencairan Dana (Karet)', 65));
    buffer.writeln(_centerText('----------------------------', 65));
    buffer.writeln();

    buffer.writeln(_leftRightAlign('ID Pencairan', ': $payoutId', 65));
    buffer.writeln(_leftRightAlign('Tanggal', ': $tanggalPayout', 65));
    buffer.writeln(_leftRightAlign('Nama Anggota', ': $namaAnggota ($anggotaId)', 65));
    buffer.writeln(divider);
    
    buffer.writeln('  No. Struk      | Tanggal    | Berat (Kg) | Nilai Kotor (Rp)');
    buffer.writeln('  -------------------------------------------------------------');
    for (int i = 0; i < weighings.length; i++) {
      final w = weighings[i];
      final noStruk = w['no_struk'] ?? '';
      final tgl = (w['waktu_input'] as String?)?.split('T').first ?? '';
      final berat = '${w['berat_kg']} Kg';
      final bruto = formatCurrency(w['harga_bruto'] ?? 0);
      
      final noStrukCol = noStruk.padRight(16);
      final tglCol = tgl.padRight(10);
      final beratCol = berat.padRight(10);
      final brutoCol = bruto.padLeft(18);
      buffer.writeln('  $noStrukCol | $tglCol | $beratCol | $brutoCol');
    }
    buffer.writeln(divider);
    buffer.writeln();

    buffer.writeln(_leftRightAlign('Total Timbangan (${weighings.length} Sesi)', ': $totalBerat Kg', 65));
    buffer.writeln(_leftRightAlign('Total Kotor (Bruto)', ': ${formatCurrency(totalBruto)}', 65));
    buffer.writeln();
    
    buffer.writeln('Potongan :');
    buffer.writeln(_leftRightAlign('- Total Administrasi', ': ${formatCurrency(totalAdm)}', 65));
    buffer.writeln(_leftRightAlign('- Total Ongkos Angkut', ': ${formatCurrency(totalTrs)}', 65));
    buffer.writeln(_leftRightAlign('- Potongan Pinjaman', ': ${formatCurrency(pinjamanDipotong)}', 65));
    buffer.writeln();

    buffer.writeln(_leftRightAlign('Total Potongan', ': ${formatCurrency(totalAdm + totalTrs + pinjamanDipotong)}', 65));
    buffer.writeln(_leftRightAlign('Jumlah Uang Diterima', ': ${formatCurrency(totalNetto)}', 65));
    buffer.writeln(divider);
    buffer.writeln();

    buffer.writeln('      Penerima / Petani                   Bendahara / Koperasi');
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln('  (                          )         (                          )');
    buffer.writeln(divider);

    return buffer.toString();
  }

  /// Print Payout receipt to a PDF layout
  static Future<void> printPayoutPdf({
    required String namaAnggota,
    required String anggotaId,
    required String tanggalPayout,
    required String payoutId,
    required List<Map<String, dynamic>> weighings,
    required int totalBerat,
    required int totalBruto,
    required int totalAdm,
    required int totalTrs,
    required int pinjamanDipotong,
    required int totalNetto,
  }) async {
    final pdf = pw.Document();

    final textRepresentation = generatePayoutTextReceipt(
      namaAnggota: namaAnggota,
      anggotaId: anggotaId,
      tanggalPayout: tanggalPayout,
      payoutId: payoutId,
      weighings: weighings,
      totalBerat: totalBerat,
      totalBruto: totalBruto,
      totalAdm: totalAdm,
      totalTrs: totalTrs,
      pinjamanDipotong: pinjamanDipotong,
      totalNetto: totalNetto,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 260 * PdfPageFormat.mm, marginAll: 5 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Text(
            textRepresentation,
            style: pw.TextStyle(
              font: pw.Font.courier(),
              fontSize: 7.5,
              lineSpacing: 1.2,
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Struk-Pencairan-$payoutId',
    );
  }

  // Alignment helpers
  static String _centerText(String text, int width, {bool alignRight = false}) {
    if (text.length >= width) return text;
    if (alignRight) {
      return text.padLeft(width);
    }
    int spaces = (width - text.length) ~/ 2;
    return ' ' * spaces + text;
  }

  static String _leftRightAlign(String left, String right, int width) {
    int spaceCount = width - left.length - right.length;
    if (spaceCount < 1) spaceCount = 1;
    return left + ' ' * spaceCount + right;
  }
}

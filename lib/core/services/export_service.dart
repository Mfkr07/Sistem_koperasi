import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/file_saver.dart';

class ExportService {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Exports Session Data to Excel
  static Future<void> exportSesiTimbangToExcel({
    required Map<String, dynamic> sesi,
    required List<Map<String, dynamic>> transaksiList,
    required List<Map<String, dynamic>> pengeluaranList,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Title Block
    sheet.appendRow([TextCellValue('LAPORAN REKAP HARIAN TPK KOPERASI KARET')]);
    sheet.appendRow([TextCellValue('KUD BERKAT - TPK MUARA UJANMAS')]);
    sheet.appendRow([]);

    // Session Meta Data
    sheet.appendRow([
      TextCellValue('Tanggal:'),
      TextCellValue(_formatDate(sesi['tanggal'])),
      TextCellValue('Sesi ID:'),
      TextCellValue(sesi['sesi_id']),
    ]);
    sheet.appendRow([
      TextCellValue('Koordinator:'),
      TextCellValue(sesi['koordinator_nama'] ?? sesi['koordinator_id']),
      TextCellValue('Harga/Kg:'),
      IntCellValue(sesi['harga_per_kg']),
    ]);
    sheet.appendRow([
      TextCellValue('Tarif ADM/Kg:'),
      IntCellValue(sesi['tarif_adm_per_kg']),
      TextCellValue('Status:'),
      TextCellValue(sesi['status']),
    ]);
    sheet.appendRow([]);

    // Transaction Table Headers
    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('No Struk'),
      TextCellValue('Nama Anggota'),
      TextCellValue('Timbangan (Kg)'),
      TextCellValue('Tipe Angkutan'),
      TextCellValue('Harga Kotor'),
      TextCellValue('Potongan ADM'),
      TextCellValue('Potongan TRS'),
      TextCellValue('Potongan Pinjaman'),
      TextCellValue('Total Potongan'),
      TextCellValue('Jumlah Dibayar'),
    ]);

    int totalTonase = 0;
    int totalKotor = 0;
    int totalAdm = 0;
    int totalTrs = 0;
    int totalPinjaman = 0;
    int totalPotongan = 0;
    int totalDibayar = 0;

    for (int i = 0; i < transaksiList.length; i++) {
      final tx = transaksiList[i];
      final no = i + 1;
      
      final berat = tx['berat_kg'] as int;
      final kotor = tx['harga_bruto'] as int;
      final adm = tx['biaya_adm'] as int;
      final trs = tx['biaya_trs'] as int;
      final pinjaman = tx['pinjaman_dipotong'] as int;
      final pot = tx['total_potongan'] as int;
      final bayar = tx['jumlah_disetor'] as int;

      totalTonase += berat;
      totalKotor += kotor;
      totalAdm += adm;
      totalTrs += trs;
      totalPinjaman += pinjaman;
      totalPotongan += pot;
      totalDibayar += bayar;

      sheet.appendRow([
        IntCellValue(no),
        TextCellValue(tx['no_struk']),
        TextCellValue(tx['anggota_nama'] ?? tx['anggota_id']),
        IntCellValue(berat),
        TextCellValue(tx['angkutan'] ?? 'SENDIRI'),
        IntCellValue(kotor),
        IntCellValue(adm),
        IntCellValue(trs),
        IntCellValue(pinjaman),
        IntCellValue(pot),
        IntCellValue(bayar),
      ]);
    }

    // Transactions Total Row
    sheet.appendRow([
      TextCellValue('TOTAL TIMBANGAN'),
      TextCellValue(''),
      TextCellValue(''),
      IntCellValue(totalTonase),
      TextCellValue(''),
      IntCellValue(totalKotor),
      IntCellValue(totalAdm),
      IntCellValue(totalTrs),
      IntCellValue(totalPinjaman),
      IntCellValue(totalPotongan),
      IntCellValue(totalDibayar),
    ]);

    sheet.appendRow([]);
    sheet.appendRow([]);

    // Expense Table Headers
    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Kategori Pengeluaran'),
      TextCellValue('Nama Penerima'),
      TextCellValue('Jumlah Pengeluaran'),
      TextCellValue('Keterangan'),
    ]);

    int totalPengeluaran = 0;
    for (int i = 0; i < pengeluaranList.length; i++) {
      final pgl = pengeluaranList[i];
      final no = i + 1;
      final jumlah = pgl['jumlah'] as int;
      totalPengeluaran += jumlah;

      sheet.appendRow([
        IntCellValue(no),
        TextCellValue(pgl['kategori']),
        TextCellValue(pgl['nama_penerima'] ?? '-'),
        IntCellValue(jumlah),
        TextCellValue(pgl['keterangan'] ?? ''),
      ]);
    }

    // Expense Total Row
    sheet.appendRow([
      TextCellValue('TOTAL PENGELUARAN'),
      TextCellValue(''),
      TextCellValue(''),
      IntCellValue(totalPengeluaran),
      TextCellValue(''),
    ]);

    sheet.appendRow([]);

    // Summary Cash Calculations
    int sisaKas = totalAdm - totalPengeluaran;
    sheet.appendRow([TextCellValue('SISA UANG KAS / KOPERASI (Total ADM - Total Pengeluaran):')]);
    sheet.appendRow([IntCellValue(sisaKas)]);

    final bytes = excel.save();
    if (bytes != null) {
      final date = sesi['tanggal'].replaceAll('-', '');
      await saveAndLaunchFile(
        Uint8List.fromList(bytes),
        'Rekap_${sesi['koordinator_nama']}_$date.xlsx',
      );
    }
  }

  /// Exports Session Data to PDF
  static Future<void> exportSesiTimbangToPdf({
    required Map<String, dynamic> sesi,
    required List<Map<String, dynamic>> transaksiList,
    required List<Map<String, dynamic>> pengeluaranList,
  }) async {
    final pdf = pw.Document();

    int totalTonase = 0;
    int totalKotor = 0;
    int totalAdm = 0;
    int totalTrs = 0;
    int totalPinjaman = 0;
    int totalPotongan = 0;
    int totalDibayar = 0;

    for (var tx in transaksiList) {
      totalTonase += (tx['berat_kg'] as num).toInt();
      totalKotor += (tx['harga_bruto'] as num).toInt();
      totalAdm += (tx['biaya_adm'] as num).toInt();
      totalTrs += (tx['biaya_trs'] as num).toInt();
      totalPinjaman += (tx['pinjaman_dipotong'] as num).toInt();
      totalPotongan += (tx['total_potongan'] as num).toInt();
      totalDibayar += (tx['jumlah_disetor'] as num).toInt();
    }

    int totalPengeluaran = 0;
    for (var pgl in pengeluaranList) {
      totalPengeluaran += (pgl['jumlah'] as num).toInt();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginBottom: 1.5 * PdfPageFormat.cm,
          marginTop: 1.5 * PdfPageFormat.cm,
          marginLeft: 1.0 * PdfPageFormat.cm,
          marginRight: 1.0 * PdfPageFormat.cm,
        ),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('KOPERASI UNIT DESA BERKAT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.Text('TPK Muara Ujanmas - Rekap Hasil Timbang Harian', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.Divider(),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          // Metadata block
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Tanggal: ${_formatDate(sesi['tanggal'])}'),
                  pw.Text('Sesi: ${sesi['sesi_id']}'),
                  pw.Text('Koordinator: ${sesi['koordinator_nama'] ?? sesi['koordinator_id']}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Harga/Kg: ${_currencyFormatter.format(sesi['harga_per_kg'])}'),
                  pw.Text('ADM/Kg: ${_currencyFormatter.format(sesi['tarif_adm_per_kg'])}'),
                  pw.Text('Status Sesi: ${sesi['status']}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Transaksi Header Label
          pw.Text('Daftar Timbangan Anggota', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 5),

          // Transaksi Table
          pw.Table.fromTextArray(
            headers: ['No', 'Struk', 'Nama', 'Berat', 'Kotor', 'ADM', 'TRS', 'Pinjaman', 'Dibayar'],
            data: List.generate(transaksiList.length, (index) {
              final tx = transaksiList[index];
              return [
                '${index + 1}',
                tx['no_struk'],
                tx['anggota_nama'] ?? tx['anggota_id'],
                '${tx['berat_kg']} Kg',
                _currencyFormatter.format(tx['harga_bruto']),
                _currencyFormatter.format(tx['biaya_adm']),
                _currencyFormatter.format(tx['biaya_trs']),
                _currencyFormatter.format(tx['pinjaman_dipotong']),
                _currencyFormatter.format(tx['jumlah_disetor']),
              ];
            }),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
          ),
          
          pw.SizedBox(height: 15),

          // Totals Summary Block
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: PdfColors.grey100,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('RINGKASAN TIMBANGAN:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Tonase: $totalTonase Kg'),
                    pw.Text('Total Bruto: ${_currencyFormatter.format(totalKotor)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total ADM TPK: ${_currencyFormatter.format(totalAdm)}'),
                    pw.Text('Total Ongkos Angkut: ${_currencyFormatter.format(totalTrs)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Potong Pinjaman: ${_currencyFormatter.format(totalPinjaman)}'),
                    pw.Text('Total Dibayar Anggota: ${_currencyFormatter.format(totalDibayar)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Pengeluaran Header
          pw.Text('Daftar Pengeluaran Operasional', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 5),

          // Pengeluaran Table
          pw.Table.fromTextArray(
            headers: ['No', 'Kategori', 'Penerima', 'Keterangan', 'Jumlah'],
            data: List.generate(pengeluaranList.length, (index) {
              final pgl = pengeluaranList[index];
              return [
                '${index + 1}',
                pgl['kategori'],
                pgl['nama_penerima'] ?? '-',
                pgl['keterangan'] ?? '-',
                _currencyFormatter.format(pgl['jumlah']),
              ];
            }),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
          ),

          pw.SizedBox(height: 15),

          // Cash Position Block
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: PdfColors.blue50,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('SISA SALDO KAS KOPERASI (ADM - Pengeluaran):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text(
                  _currencyFormatter.format(totalAdm - totalPengeluaran),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    final date = sesi['tanggal'].replaceAll('-', '');
    await saveAndLaunchFile(
      pdfBytes,
      'Rekap_${sesi['koordinator_nama']}_$date.pdf',
    );
  }
}

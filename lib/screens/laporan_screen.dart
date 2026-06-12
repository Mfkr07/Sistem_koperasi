import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/constants/strings.dart';
import '../providers/app_state_provider.dart';
import '../core/services/printer_service.dart';
import '../core/services/export_service.dart';
import '../core/services/kalkulasi_service.dart';
import '../core/database/database_helper.dart';
import '../widgets/table_pagination.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  String _searchFilter = '';
  List<Map<String, dynamic>> _allTransactions = [];
  bool _isLoading = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadAllTransactions();
  }

  Future<void> _loadAllTransactions() async {
    setState(() => _isLoading = true);
    final dbHelper = DatabaseHelper.instance;
    final txList = await dbHelper.query('transaksi', orderBy: 'waktu_input DESC');
    
    List<Map<String, dynamic>> hydrated = [];
    for (var tx in txList) {
      final map = Map<String, dynamic>.from(tx);
      
      // Hydrate Member
      final member = await dbHelper.query('anggota', where: 'anggota_id = ?', whereArgs: [tx['anggota_id']]);
      if (member.isNotEmpty) {
        map['anggota_nama'] = member.first['nama'];
        map['angkutan'] = member.first['tipe_angkutan'];
      }
      
      // Hydrate Session
      final session = await dbHelper.query('sesi_timbang', where: 'sesi_id = ?', whereArgs: [tx['sesi_id']]);
      if (session.isNotEmpty) {
        map['harga_per_kg'] = session.first['harga_per_kg'];
        map['tarif_adm'] = session.first['tarif_adm_per_kg'];
        
        final calc = KalkulasiService.hitung(
          beratTotal: tx['berat_kg'] as int,
          porsiPersen: 100.0,
          hargaPerKg: session.first['harga_per_kg'] as int,
          tarifAdm: session.first['tarif_adm_per_kg'] as int,
          tarifTrsDusun: session.first['tarif_trs_dusun'] as int,
          tarifTrsIbol: session.first['tarif_trs_ibol'] as int,
          tipeAngkutan: map['angkutan'] ?? 'SENDIRI',
          pinjamanDipotong: tx['pinjaman_dipotong'] as int,
        );

        map['harga_bruto'] = calc.hargaBruto;
        map['biaya_adm'] = calc.biayaAdm;
        map['biaya_trs'] = calc.biayaTrs;
        map['total_potongan'] = calc.totalPotongan;
        map['jumlah_disetor'] = calc.jumlahDisetor;
        map['tanggal'] = session.first['tanggal'];
      }

      hydrated.add(map);
    }

    setState(() {
      _allTransactions = hydrated;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allTransactions.where((tx) {
      final name = (tx['anggota_nama'] ?? '').toString().toLowerCase();
      final id = tx['anggota_id'].toString().toLowerCase();
      final struk = tx['no_struk'].toString().toLowerCase();
      final query = _searchFilter.toLowerCase();
      return name.contains(query) || id.contains(query) || struk.contains(query);
    }).toList();

    // Summary calculations
    int totalTonase = 0;
    int totalKotor = 0;
    int totalAdm = 0;
    int totalTrs = 0;
    int totalPinjaman = 0;
    int totalDibayar = 0;

    for (var tx in filtered) {
      if (tx['is_void'] == 1) continue; // skip voided in summaries
      totalTonase += (tx['berat_kg'] as num).toInt();
      totalKotor += (tx['harga_bruto'] as num? ?? 0).toInt();
      totalAdm += (tx['biaya_adm'] as num? ?? 0).toInt();
      totalTrs += (tx['biaya_trs'] as num? ?? 0).toInt();
      totalPinjaman += (tx['pinjaman_dipotong'] as num? ?? 0).toInt();
      totalDibayar += (tx['jumlah_disetor'] as num? ?? 0).toInt();
    }

    return Scaffold(
      backgroundColor: CarbonColors.canvas,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Global Exports
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laporan & Audit Global',
                        style: CarbonTypography.headline.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monitoring rekap timbangan dan keuangan koperasi sawit.',
                        style: CarbonTypography.caption,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    _buildExportButton(
                      label: 'Ekspor Excel',
                      icon: Icons.table_view,
                      color: CarbonColors.success,
                      onTap: () => _exportGlobalExcel(filtered),
                    ),
                    const SizedBox(width: 16),
                    _buildExportButton(
                      label: 'Ekspor PDF',
                      icon: Icons.picture_as_pdf,
                      color: CarbonColors.primary,
                      onTap: () => _exportGlobalPdf(filtered),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 48, color: CarbonColors.hairline),

            // Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() {
                      _searchFilter = val;
                      _currentPage = 1;
                    }),
                    decoration: const InputDecoration(
                      hintText: 'Cari transaksi berdasarkan nama, ID anggota, atau nomor struk...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      fillColor: CarbonColors.surface1,
                      filled: true,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  tooltip: 'Segarkan Data',
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAllTransactions,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metrics overview bar
            _buildMetricsOverviewBar(
              tonase: totalTonase,
              kotor: totalKotor,
              adm: totalAdm,
              trs: totalTrs,
              pinjaman: totalPinjaman,
              dibayar: totalDibayar,
            ),
            const SizedBox(height: 24),

            // Table View
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: CarbonColors.hairline, width: 1),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(child: Text('Tidak ada data transaksi yang cocok.'))
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.separated(
                                  itemCount: () {
                                    final int itemsPerPage = 10;
                                    final int totalItems = filtered.length;
                                    final int totalPages = (totalItems / itemsPerPage).ceil();
                                    int page = _currentPage;
                                    if (page > totalPages && totalPages > 0) {
                                      page = totalPages;
                                    }
                                    final int startIndex = (page - 1) * itemsPerPage;
                                    final int endIndex = startIndex + itemsPerPage;
                                    final paginatedList = filtered.sublist(
                                      startIndex,
                                      endIndex > totalItems ? totalItems : endIndex,
                                    );
                                    return paginatedList.length;
                                  }(),
                                  separatorBuilder: (c, i) => const Divider(height: 1, color: CarbonColors.hairline),
                                  itemBuilder: (c, idx) {
                                    final int itemsPerPage = 10;
                                    final int totalItems = filtered.length;
                                    final int totalPages = (totalItems / itemsPerPage).ceil();
                                    int page = _currentPage;
                                    if (page > totalPages && totalPages > 0) {
                                      page = totalPages;
                                    }
                                    final int startIndex = (page - 1) * itemsPerPage;
                                    final int endIndex = startIndex + itemsPerPage;
                                    final paginatedList = filtered.sublist(
                                      startIndex,
                                      endIndex > totalItems ? totalItems : endIndex,
                                    );
                                    
                                    final tx = paginatedList[idx];
                                    final isVoid = tx['is_void'] == 1;

                                    return ListTile(
                                      tileColor: isVoid ? CarbonColors.surface1 : CarbonColors.canvas,
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${tx['anggota_nama'] ?? tx['anggota_id']}',
                                              style: TextStyle(
                                                decoration: isVoid ? TextDecoration.lineThrough : null,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isVoid) ...[
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              color: CarbonColors.error.withOpacity(0.1),
                                              child: const Text(
                                                'VOID',
                                                style: TextStyle(color: CarbonColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                      subtitle: Text(
                                        'Struk: ${tx['no_struk']} • Tanggal Sesi: ${tx['tanggal'] ?? tx['sesi_id']} • Berat: ${tx['berat_kg']} Kg\nPotongan: Adm (${PrinterService.formatCurrency(tx['biaya_adm'] ?? 0)}) | TRS (${PrinterService.formatCurrency(tx['biaya_trs'] ?? 0)}) | Pinjaman (${PrinterService.formatCurrency(tx['pinjaman_dipotong'])})'
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            PrinterService.formatCurrency(tx['jumlah_disetor'] ?? 0),
                                            style: CarbonTypography.bodyEmphasis.copyWith(
                                              decoration: isVoid ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                          if (!isVoid) ...[
                                            const SizedBox(height: 4),
                                            InkWell(
                                              onTap: () => _confirmVoid(context, tx['transaksi_id']),
                                              child: const Text(
                                                'Batalkan (Void)',
                                                style: TextStyle(color: CarbonColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              TablePagination(
                                currentPage: () {
                                  final int itemsPerPage = 10;
                                  final int totalItems = filtered.length;
                                  final int totalPages = (totalItems / itemsPerPage).ceil();
                                  int page = _currentPage;
                                  if (page > totalPages && totalPages > 0) {
                                    page = totalPages;
                                  }
                                  return page;
                                }(),
                                totalItems: filtered.length,
                                itemsPerPage: 10,
                                onPageChanged: (newPage) {
                                  setState(() {
                                    _currentPage = newPage;
                                  });
                                },
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricsOverviewBar({
    required int tonase,
    required int kotor,
    required int adm,
    required int trs,
    required int pinjaman,
    required int dibayar,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CarbonColors.surface1,
        border: Border.all(color: CarbonColors.hairline),
      ),
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 20,
        runSpacing: 16,
        children: [
          _buildMiniMetric('Total Tonase', '$tonase Kg'),
          _buildMiniMetric('Total Bruto', PrinterService.formatCurrency(kotor)),
          _buildMiniMetric('Total ADM TPK', PrinterService.formatCurrency(adm)),
          _buildMiniMetric('Total TRS', PrinterService.formatCurrency(trs)),
          _buildMiniMetric('Total Potong Pinjaman', PrinterService.formatCurrency(pinjaman)),
          _buildMiniMetric('Total Net Payout', PrinterService.formatCurrency(dibayar), highlight: true),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String val, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: CarbonTypography.caption),
        const SizedBox(height: 6),
        Text(
          val,
          style: CarbonTypography.bodyEmphasis.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? CarbonColors.primary : CarbonColors.ink,
          ),
        ),
      ],
    );
  }

  void _confirmVoid(BuildContext context, String transaksiId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Batalkan Transaksi (Void)'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan transaksi ini?\nNominal potongan pinjaman akan dikembalikan ke saldo hutang petani secara otomatis.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal', style: TextStyle(color: CarbonColors.ink)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              await context.read<AppStateProvider>().voidTransaksi(transaksiId);
              await _loadAllTransactions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaksi berhasil dibatalkan (Void).')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CarbonColors.error,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('Void Transaksi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Global Excel Export
  Future<void> _exportGlobalExcel(List<Map<String, dynamic>> dataList) async {
    final sesiPlaceholder = {
      'sesi_id': 'GLOBAL_AUDIT',
      'tanggal': DateTime.now().toIso8601String().split('T')[0],
      'koordinator_nama': 'Semua Koordinator',
      'harga_per_kg': 0,
      'tarif_adm_per_kg': 0,
      'status': 'LAPORAN REKAP AUDIT GLOBAL',
    };
    await ExportService.exportSesiTimbangToExcel(
      sesi: sesiPlaceholder,
      transaksiList: dataList,
      pengeluaranList: [],
    );
  }

  // Global PDF Export
  Future<void> _exportGlobalPdf(List<Map<String, dynamic>> dataList) async {
    final sesiPlaceholder = {
      'sesi_id': 'GLOBAL_AUDIT',
      'tanggal': DateTime.now().toIso8601String().split('T')[0],
      'koordinator_nama': 'Semua Koordinator',
      'harga_per_kg': 0,
      'tarif_adm_per_kg': 0,
      'status': 'LAPORAN REKAP AUDIT GLOBAL',
    };
    await ExportService.exportSesiTimbangToPdf(
      sesi: sesiPlaceholder,
      transaksiList: dataList,
      pengeluaranList: [],
    );
  }
}

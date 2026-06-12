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
import '../models/sesi_timbang.dart';
import '../widgets/table_pagination.dart';

class SesiTimbangScreen extends StatefulWidget {
  const SesiTimbangScreen({super.key});

  @override
  State<SesiTimbangScreen> createState() => _SesiTimbangScreenState();
}

class _SesiTimbangScreenState extends State<SesiTimbangScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedKoorId;
  final _tanggalController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
  final _hargaController = TextEditingController(text: '16900');
  final _admController = TextEditingController(text: '100');
  final _trsDusunController = TextEditingController(text: '100');
  final _trsIbolController = TextEditingController(text: '350');
  final _catatanController = TextEditingController();
  int _currentPageHistory = 1;

  // Expense form fields
  final _expKategoriController = TextEditingController(text: 'TENAGA_KERJA');
  final _expPenerimaController = TextEditingController();
  final _expJumlahController = TextEditingController();
  final _expKetController = TextEditingController();

  @override
  void dispose() {
    _tanggalController.dispose();
    _hargaController.dispose();
    _admController.dispose();
    _trsDusunController.dispose();
    _trsIbolController.dispose();
    _catatanController.dispose();
    _expPenerimaController.dispose();
    _expJumlahController.dispose();
    _expKetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: CarbonColors.canvas,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column: Sesi Form or Active Sesi Details
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesi Timbang Harian',
                      style: CarbonTypography.headline.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    
                    if (state.activeSesi != null) ...[
                      _buildActiveSessionCard(context, state),
                    ] else ...[
                      _buildBukaSesiForm(context, state),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(width: 40),
            
            // Right Column: Sesi History
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Sesi Timbang',
                    style: CarbonTypography.subhead.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: CarbonColors.hairline, width: 1),
                      ),
                      child: state.sessions.isEmpty
                          ? const Center(child: Text('Belum ada riwayat sesi.'))
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: () {
                                      final int itemsPerPage = 10;
                                      final int totalItems = state.sessions.length;
                                      final int totalPages = (totalItems / itemsPerPage).ceil();
                                      int page = _currentPageHistory;
                                      if (page > totalPages && totalPages > 0) {
                                        page = totalPages;
                                      }
                                      final int startIndex = (page - 1) * itemsPerPage;
                                      final int endIndex = startIndex + itemsPerPage;
                                      final paginatedList = state.sessions.sublist(
                                        startIndex,
                                        endIndex > totalItems ? totalItems : endIndex,
                                      );
                                      return paginatedList.length;
                                    }(),
                                    separatorBuilder: (c, i) => const Divider(height: 1, color: CarbonColors.hairline),
                                    itemBuilder: (c, idx) {
                                      final int itemsPerPage = 10;
                                      final int totalItems = state.sessions.length;
                                      final int totalPages = (totalItems / itemsPerPage).ceil();
                                      int page = _currentPageHistory;
                                      if (page > totalPages && totalPages > 0) {
                                        page = totalPages;
                                      }
                                      final int startIndex = (page - 1) * itemsPerPage;
                                      final int endIndex = startIndex + itemsPerPage;
                                      final paginatedList = state.sessions.sublist(
                                        startIndex,
                                        endIndex > totalItems ? totalItems : endIndex,
                                      );
                                      
                                      final sesi = paginatedList[idx];
                                      final koor = state.koordinators.firstWhere(
                                        (k) => k.koordinatorId == sesi.koordinatorId,
                                        orElse: () => state.koordinators.first,
                                      );
                                      
                                      return ListTile(
                                        tileColor: CarbonColors.canvas,
                                        title: Text('${sesi.tanggal} - ${koor.nama}'),
                                        subtitle: Text(
                                          'Harga: ${PrinterService.formatCurrency(sesi.hargaPerKg)} • ${sesi.status}'
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'Ekspor Excel',
                                              icon: const Icon(Icons.table_view, color: CarbonColors.success),
                                              onPressed: () => _exportSessionData(context, sesi, isExcel: true),
                                            ),
                                            IconButton(
                                              tooltip: 'Ekspor PDF',
                                              icon: const Icon(Icons.picture_as_pdf, color: CarbonColors.primary),
                                              onPressed: () => _exportSessionData(context, sesi, isExcel: false),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                TablePagination(
                                  currentPage: () {
                                    final int itemsPerPage = 10;
                                    final int totalItems = state.sessions.length;
                                    final int totalPages = (totalItems / itemsPerPage).ceil();
                                    int page = _currentPageHistory;
                                    if (page > totalPages && totalPages > 0) {
                                      page = totalPages;
                                    }
                                    return page;
                                  }(),
                                  totalItems: state.sessions.length,
                                  itemsPerPage: 10,
                                  onPageChanged: (newPage) {
                                    setState(() {
                                      _currentPageHistory = newPage;
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
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionCard(BuildContext context, AppStateProvider state) {
    final active = state.activeSesi!;
    final koor = state.koordinators.firstWhere(
      (k) => k.koordinatorId == active.koordinatorId,
      orElse: () => state.koordinators.first,
    );

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: CarbonColors.surface1,
        border: Border.all(color: CarbonColors.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SESI TIMBANG AKTIF',
                style: CarbonTypography.eyebrow.copyWith(color: CarbonColors.primary, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: CarbonColors.primary,
                child: Text(
                  active.sesiId,
                  style: CarbonTypography.caption.copyWith(color: CarbonColors.onPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Koordinator', koor.nama),
          _buildDetailRow('Tanggal Sesi', active.tanggal),
          _buildDetailRow('Harga per Kg', PrinterService.formatCurrency(active.hargaPerKg)),
          _buildDetailRow('Tarif ADM', '${active.tarifAdmPerKg} / Kg'),
          _buildDetailRow('Tarif TRS Dusun', '${active.tarifTrsDusun} / Kg'),
          _buildDetailRow('Tarif TRS Ibol', '${active.tarifTrsIbol} / Kg'),
          const Divider(height: 32, color: CarbonColors.hairline),
          
          // Operational Expenses Panel
          Text(
            'Biaya Operasional Sesi',
            style: CarbonTypography.bodyEmphasis.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildExpensesList(state),
          const SizedBox(height: 16),
          _buildAddExpenseRow(state),

          const Divider(height: 32, color: CarbonColors.hairline),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmTutupSesi(context, state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CarbonColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Text(
                    'TUTUP SESI & REKAP KAS',
                    style: CarbonTypography.button.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBukaSesiForm(BuildContext context, AppStateProvider state) {
    if (_selectedKoorId == null && state.koordinators.isNotEmpty) {
      _selectedKoorId = state.koordinators.first.koordinatorId;
    }

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: CarbonColors.canvas,
          border: Border.all(color: CarbonColors.hairline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buka Sesi Timbang Baru',
              style: CarbonTypography.bodyEmphasis.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Koordinator Dropdown
            Text('Pilih Koordinator', style: CarbonTypography.caption),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedKoorId,
              isExpanded: true,
              items: state.koordinators.map((k) {
                return DropdownMenuItem(
                  value: k.koordinatorId,
                  child: Text(k.nama),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedKoorId = val),
              decoration: const InputDecoration(
                fillColor: CarbonColors.surface1,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
            ),
            const SizedBox(height: 20),

            // Tanggal
            Text('Tanggal Timbang', style: CarbonTypography.caption),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tanggalController,
              decoration: const InputDecoration(
                hintText: 'YYYY-MM-DD',
                fillColor: CarbonColors.surface1,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
            ),
            const SizedBox(height: 20),

            // Harga
            Text('Harga per Kg (Rp.)', style: CarbonTypography.caption),
            const SizedBox(height: 8),
            TextFormField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                fillColor: CarbonColors.surface1,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
            ),
            const SizedBox(height: 20),

            // ADM / TRS
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ADM per Kg', style: CarbonTypography.caption),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _admController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          fillColor: CarbonColors.surface1,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRS Dusun', style: CarbonTypography.caption),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _trsDusunController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          fillColor: CarbonColors.surface1,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRS Ibol', style: CarbonTypography.caption),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _trsIbolController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          fillColor: CarbonColors.surface1,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_selectedKoorId == null) return;
                      final ok = await state.bukaSesi(
                        koordinatorId: _selectedKoorId!,
                        tanggal: _tanggalController.text,
                        hargaPerKg: int.parse(_hargaController.text),
                        tarifAdm: int.parse(_admController.text),
                        tarifTrsDusun: int.parse(_trsDusunController.text),
                        tarifTrsIbol: int.parse(_trsIbolController.text),
                        catatan: _catatanController.text,
                      );

                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sesi Timbang dibuka.')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error: Sesi koordinator pada tanggal ini sudah ada.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CarbonColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Text(
                      'BUKA SESI TIMBANG',
                      style: CarbonTypography.button.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CarbonTypography.bodySm.copyWith(color: CarbonColors.inkMuted)),
          Text(value, style: CarbonTypography.bodySm.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExpensesList(AppStateProvider state) {
    if (state.activeSessionExpenses.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        color: CarbonColors.surface2,
        child: Text('Belum ada pengeluaran operasional', style: CarbonTypography.caption),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        border: Border.all(color: CarbonColors.hairline),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: state.activeSessionExpenses.length,
        itemBuilder: (c, idx) {
          final exp = state.activeSessionExpenses[idx];
          return ListTile(
            dense: true,
            title: Text('${exp['kategori']} - ${exp['nama_penerima'] ?? '-'}'),
            subtitle: Text(PrinterService.formatCurrency(exp['jumlah'])),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: CarbonColors.error),
              onPressed: () => state.hapusPengeluaran(exp['pengeluaran_id']),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddExpenseRow(AppStateProvider state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _expKategoriController.text,
                items: const [
                  DropdownMenuItem(value: 'TENAGA_KERJA', child: Text('Tenaga Kerja')),
                  DropdownMenuItem(value: 'KUD', child: Text('KUD')),
                  DropdownMenuItem(value: 'JAGA_MALAM', child: Text('Jaga Malam')),
                  DropdownMenuItem(value: 'TRUCK', child: Text('Truck')),
                  DropdownMenuItem(value: 'KAS', child: Text('Kas TPK')),
                  DropdownMenuItem(value: 'LAIN', child: Text('Lainnya')),
                ],
                onChanged: (val) {
                  if (val != null) _expKategoriController.text = val;
                },
                decoration: const InputDecoration(
                  fillColor: CarbonColors.canvas,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _expPenerimaController,
                decoration: const InputDecoration(
                  hintText: 'Nama Penerima',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _expJumlahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Jumlah Rp',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final nominal = int.tryParse(_expJumlahController.text);
                if (nominal != null && nominal > 0) {
                  state.tambahPengeluaran(
                    _expKategoriController.text,
                    _expPenerimaController.text.isEmpty ? null : _expPenerimaController.text,
                    nominal,
                    _expKetController.text.isEmpty ? null : _expKetController.text,
                  );
                  // Reset fields
                  _expPenerimaController.clear();
                  _expJumlahController.clear();
                  _expKetController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CarbonColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmTutupSesi(BuildContext context, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tutup Sesi Timbang'),
        content: const Text(
          'Apakah Anda yakin ingin menutup sesi ini? Semua data sesi ini akan diarsipkan dan tidak dapat diubah.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal', style: TextStyle(color: CarbonColors.ink)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              await state.tutupSesi();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sesi Timbang berhasil ditutup.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CarbonColors.primary,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('Tutup Sesi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSessionData(BuildContext context, SesiTimbang sesi, {required bool isExcel}) async {
    final dbHelper = DatabaseHelper.instance;
    
    // Fetch transaction list for this historical session
    final txList = await dbHelper.query(
      'transaksi',
      where: 'sesi_id = ?',
      whereArgs: [sesi.sesiId],
    );

    List<Map<String, dynamic>> hydratedTx = [];
    for (var tx in txList) {
      final map = Map<String, dynamic>.from(tx);
      final memberList = await dbHelper.query('anggota', where: 'anggota_id = ?', whereArgs: [tx['anggota_id']]);
      if (memberList.isNotEmpty) {
        map['anggota_nama'] = memberList.first['nama'];
        map['angkutan'] = memberList.first['tipe_angkutan'];
      }
      
      final calc = KalkulasiService.hitung(
        beratTotal: tx['berat_kg'] as int,
        porsiPersen: 100.0,
        hargaPerKg: sesi.hargaPerKg,
        tarifAdm: sesi.tarifAdmPerKg,
        tarifTrsDusun: sesi.tarifTrsDusun,
        tarifTrsIbol: sesi.tarifTrsIbol,
        tipeAngkutan: map['angkutan'] ?? 'SENDIRI',
        pinjamanDipotong: tx['pinjaman_dipotong'] as int,
      );

      map['harga_bruto'] = calc.hargaBruto;
      map['biaya_adm'] = calc.biayaAdm;
      map['biaya_trs'] = calc.biayaTrs;
      map['total_potongan'] = calc.totalPotongan;
      map['jumlah_disetor'] = calc.jumlahDisetor;

      hydratedTx.add(map);
    }

    final pglList = await dbHelper.query(
      'pengeluaran',
      where: 'sesi_id = ?',
      whereArgs: [sesi.sesiId],
    );

    final sesiMap = sesi.toMap();
    // Hydrate coordinator name
    final koorList = await dbHelper.query('koordinator', where: 'koordinator_id = ?', whereArgs: [sesi.koordinatorId]);
    if (koorList.isNotEmpty) {
      sesiMap['koordinator_nama'] = koorList.first['nama'];
    }

    if (isExcel) {
      await ExportService.exportSesiTimbangToExcel(
        sesi: sesiMap,
        transaksiList: hydratedTx,
        pengeluaranList: pglList,
      );
    } else {
      await ExportService.exportSesiTimbangToPdf(
        sesi: sesiMap,
        transaksiList: hydratedTx,
        pengeluaranList: pglList,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/constants/strings.dart';
import '../providers/app_state_provider.dart';
import '../core/services/printer_service.dart';
import '../widgets/table_pagination.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  int _activeTab = 0; // 0 for Pencairan Baru, 1 for Riwayat Pencairan
  
  // Tab 0: New Payout states
  String _searchQuery = '';
  String? _selectedAnggotaId;
  final _potongController = TextEditingController(text: '0');
  List<Map<String, dynamic>> _unpaidTx = [];
  int _outstandingLoan = 0;
  bool _loadingTx = false;

  // Tab 1: Payout History states
  List<Map<String, dynamic>> _payoutHistory = [];
  bool _loadingHistory = false;
  String _historySearchQuery = '';
  int _historyPage = 1;

  @override
  void dispose() {
    _potongController.dispose();
    super.dispose();
  }

  Future<void> _loadPayoutHistory(AppStateProvider state) async {
    setState(() => _loadingHistory = true);
    try {
      final list = await state.getAllPencairan();
      setState(() {
        _payoutHistory = list;
      });
    } catch (_) {
      // Safely handle errors
    } finally {
      setState(() => _loadingHistory = false);
    }
  }

  void _onTabChanged(int index, AppStateProvider state) {
    setState(() {
      _activeTab = index;
    });
    if (index == 1) {
      _loadPayoutHistory(state);
    }
  }

  Future<void> _onMemberSelected(AppStateProvider state, String anggotaId) async {
    setState(() {
      _selectedAnggotaId = anggotaId;
      _loadingTx = true;
      _potongController.text = '0';
    });

    try {
      final tx = await state.getUnpaidTransactions(anggotaId);
      final loans = await state.getHistoriPinjaman(anggotaId);
      
      int activeLoanSum = 0;
      for (var l in loans) {
        if (l['status'] == 'AKTIF') {
          activeLoanSum += (l['saldo_sisa'] as num).toInt();
        }
      }

      setState(() {
        _unpaidTx = tx;
        _outstandingLoan = activeLoanSum;
      });
    } catch (_) {
      // Handle error safely
    } finally {
      setState(() {
        _loadingTx = false;
      });
    }
  }

  Widget _buildTabButton(String text, int index, AppStateProvider state) {
    final active = _activeTab == index;
    return InkWell(
      onTap: () => _onTabChanged(index, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? CarbonColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? CarbonColors.primary : CarbonColors.inkMuted,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: CarbonColors.canvas,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header with Tabs
            Row(
              children: [
                Text(
                  'Pencairan Dana (Cash Out)',
                  style: CarbonTypography.headline.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildTabButton('Pencairan Baru', 0, state),
                const SizedBox(width: 16),
                _buildTabButton('Riwayat Pencairan', 1, state),
              ],
            ),
            const Divider(height: 32, color: CarbonColors.hairline),

            // Tab View Body
            Expanded(
              child: _activeTab == 0
                  ? _buildNewPayoutTab(state)
                  : _buildHistoryTab(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPayoutTab(AppStateProvider state) {
    final filteredMembers = state.anggotaList.where((a) {
      final query = _searchQuery.toLowerCase();
      return a.nama.toLowerCase().contains(query) || a.anggotaId.toLowerCase().contains(query);
    }).toList();

    final selectedMember = _selectedAnggotaId != null
        ? state.anggotaList.firstWhere((a) => a.anggotaId == _selectedAnggotaId, orElse: () => state.anggotaList.first)
        : null;

    // Calculations
    int totalBerat = 0;
    int totalBruto = 0;
    int totalAdm = 0;
    int totalTrs = 0;
    int totalNetto = 0;

    for (var tx in _unpaidTx) {
      totalBerat += tx['berat_kg'] as int;
      totalBruto += tx['harga_bruto'] as int;
      totalAdm += tx['biaya_adm'] as int;
      totalTrs += tx['biaya_trs'] as int;
      totalNetto += tx['jumlah_disetor'] as int;
    }

    final int potongPinjaman = int.tryParse(_potongController.text) ?? 0;
    final int finalPayout = totalNetto - potongPinjaman;

    // Generate live receipt preview text
    final String previewText = selectedMember != null
        ? PrinterService.generatePayoutTextReceipt(
            namaAnggota: selectedMember.nama,
            anggotaId: selectedMember.anggotaId,
            tanggalPayout: DateTime.now().toIso8601String().substring(0, 10),
            payoutId: 'PREVIEW-OUT-001',
            weighings: _unpaidTx,
            totalBerat: totalBerat,
            totalBruto: totalBruto,
            totalAdm: totalAdm,
            totalTrs: totalTrs,
            pinjamanDipotong: potongPinjaman,
            totalNetto: finalPayout,
          )
        : 'Silakan pilih petani untuk melihat pratinjau struk pencairan.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column 1: Search & Unpaid Weighings Table (flex: 5)
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Selector
              if (_selectedAnggotaId == null) ...[
                Text('Pilih Petani / Anggota', style: CarbonTypography.caption),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Cari nama atau ID petani...',
                    prefixIcon: Icon(Icons.search),
                    fillColor: CarbonColors.surface1,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      border: Border.all(color: CarbonColors.hairline),
                      color: CarbonColors.surface1,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredMembers.length,
                      itemBuilder: (c, idx) {
                        final m = filteredMembers[idx];
                        return ListTile(
                          title: Text(m.nama),
                          subtitle: Text(m.anggotaId),
                          onTap: () => _onMemberSelected(state, m.anggotaId),
                        );
                      },
                    ),
                  ),
                ],
              ] else ...[
                // Active selection card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: CarbonColors.surface2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedMember?.nama ?? '',
                            style: CarbonTypography.bodyEmphasis.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            selectedMember?.anggotaId ?? '',
                            style: CarbonTypography.caption,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: CarbonColors.error),
                        onPressed: () => setState(() {
                          _selectedAnggotaId = null;
                          _unpaidTx.clear();
                          _outstandingLoan = 0;
                          _searchQuery = '';
                          _potongController.text = '0';
                        }),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Unpaid weighings list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: CarbonColors.hairline),
                    color: CarbonColors.surface1,
                  ),
                  child: _selectedAnggotaId == null
                      ? const Center(child: Text('Silakan pilih petani terlebih dahulu.'))
                      : _loadingTx
                          ? const Center(child: CircularProgressIndicator())
                          : _unpaidTx.isEmpty
                              ? const Center(child: Text('Semua timbangan petani ini sudah dicairkan (Saldo Kosong).'))
                              : Column(
                                  children: [
                                    // Table Header
                                    Container(
                                      color: CarbonColors.surface2,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: const [
                                          Expanded(flex: 3, child: Text('No. Struk', style: TextStyle(fontWeight: FontWeight.bold))),
                                          Expanded(flex: 2, child: Text('Berat', style: TextStyle(fontWeight: FontWeight.bold))),
                                          Expanded(flex: 3, child: Text('Bruto', style: TextStyle(fontWeight: FontWeight.bold))),
                                          Expanded(flex: 2, child: Text('ADM', style: TextStyle(fontWeight: FontWeight.bold))),
                                          Expanded(flex: 2, child: Text('Transport', style: TextStyle(fontWeight: FontWeight.bold))),
                                          Expanded(flex: 3, child: Text('Netto', style: TextStyle(fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1, color: CarbonColors.hairline),
                                    // Table Body
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: _unpaidTx.length,
                                        separatorBuilder: (c, i) => const Divider(height: 1, color: CarbonColors.hairline),
                                        itemBuilder: (c, idx) {
                                          final tx = _unpaidTx[idx];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            child: Row(
                                              children: [
                                                Expanded(flex: 3, child: Text(tx['no_struk'] ?? '')),
                                                Expanded(flex: 2, child: Text('${tx['berat_kg']} Kg')),
                                                Expanded(flex: 3, child: Text(PrinterService.formatCurrency(tx['harga_bruto'] ?? 0))),
                                                Expanded(flex: 2, child: Text(PrinterService.formatCurrency(tx['biaya_adm'] ?? 0))),
                                                Expanded(flex: 2, child: Text(PrinterService.formatCurrency(tx['biaya_trs'] ?? 0))),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    PrinterService.formatCurrency(tx['jumlah_disetor'] ?? 0),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: CarbonColors.success),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // Column 2: Summary, Loans & Actions Panel (flex: 3)
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: CarbonColors.surface1,
                border: Border.all(color: CarbonColors.hairline, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Pencairan',
                    style: CarbonTypography.bodyEmphasis.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  _buildSummaryRow('Total Timbangan', '${_unpaidTx.length} Sesi'),
                  _buildSummaryRow('Total Berat', '$totalBerat Kg'),
                  _buildSummaryRow('Total Kotor (Bruto)', PrinterService.formatCurrency(totalBruto)),
                  _buildSummaryRow('Administrasi', '- ${PrinterService.formatCurrency(totalAdm)}'),
                  _buildSummaryRow('Transportasi', '- ${PrinterService.formatCurrency(totalTrs)}'),
                  const Divider(height: 32, color: CarbonColors.hairline),
                  _buildSummaryRow(
                    'Subtotal Netto',
                    PrinterService.formatCurrency(totalNetto),
                    isBold: true,
                    textColor: CarbonColors.success,
                  ),
                  const SizedBox(height: 24),

                  // Outstanding Loan Info
                  if (_selectedAnggotaId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: _outstandingLoan > 0 ? CarbonColors.error.withOpacity(0.05) : CarbonColors.success.withOpacity(0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INFORMASI PINJAMAN AKTIF',
                            style: CarbonTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _outstandingLoan > 0 ? CarbonColors.error : CarbonColors.success,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pinjaman Aktif'),
                              Text(
                                PrinterService.formatCurrency(_outstandingLoan),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Deduct Input
                  if (_selectedAnggotaId != null && _outstandingLoan > 0 && totalNetto > 0) ...[
                    Text('Potongan Pinjaman (Rp)', style: CarbonTypography.caption),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _potongController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final input = int.tryParse(val) ?? 0;
                        if (input > _outstandingLoan) {
                          _potongController.text = _outstandingLoan.toString();
                        } else if (input > totalNetto) {
                          _potongController.text = totalNetto.toString();
                        }
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        fillColor: CarbonColors.canvas,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Divider(height: 32, color: CarbonColors.hairline),
                  _buildSummaryRow(
                    'TOTAL DITERIMA',
                    PrinterService.formatCurrency(finalPayout),
                    isBold: true,
                    fontSize: 16,
                    textColor: CarbonColors.primary,
                  ),
                  const SizedBox(height: 32),

                  // Process Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_selectedAnggotaId == null || _unpaidTx.isEmpty || finalPayout < 0)
                          ? null
                          : () async {
                              final success = await state.pencairkanDana(
                                anggotaId: _selectedAnggotaId!,
                                pinjamanDipotong: potongPinjaman,
                              );

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pencairan dana berhasil diproses & struk dicetak.')),
                                );
                                setState(() {
                                  _selectedAnggotaId = null;
                                  _unpaidTx.clear();
                                  _outstandingLoan = 0;
                                  _potongController.text = '0';
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Gagal melakukan pencairan dana.')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CarbonColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text(
                        'PROSES PENCAIRAN & CETAK',
                        style: CarbonTypography.button.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 32),

        // Column 3: Thermal Receipt Preview Emulator (flex: 3)
        Expanded(
          flex: 3,
          child: Container(
            color: CarbonColors.surface1,
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pratinjau Struk Pencairan',
                  style: CarbonTypography.bodyEmphasis.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFF4),
                      border: Border.all(color: CarbonColors.hairline, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Text(
                        previewText,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          height: 1.25,
                          color: Color(0xFF161616),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(AppStateProvider state) {
    final filtered = _payoutHistory.where((p) {
      final q = _historySearchQuery.toLowerCase();
      final name = (p['anggota_nama'] ?? '').toString().toLowerCase();
      final memberId = p['anggota_id'].toString().toLowerCase();
      final payoutId = p['pencairan_id'].toString().toLowerCase();
      return name.contains(q) || memberId.contains(q) || payoutId.contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          onChanged: (val) => setState(() {
            _historySearchQuery = val;
            _historyPage = 1;
          }),
          decoration: const InputDecoration(
            hintText: 'Cari riwayat berdasarkan nama, ID petani, atau ID pencairan...',
            prefixIcon: Icon(Icons.search),
            fillColor: CarbonColors.surface1,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        const SizedBox(height: 24),

        // Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: CarbonColors.hairline),
              color: CarbonColors.surface1,
            ),
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Tidak ada riwayat pencairan.'))
                    : Column(
                        children: [
                          // Header
                          Container(
                            color: CarbonColors.surface2,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: const [
                                Expanded(flex: 3, child: Text('ID Pencairan', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 3, child: Text('Petani', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Total Berat', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Potongan', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 3, child: Text('Total Netto', style: TextStyle(fontWeight: FontWeight.bold))),
                                SizedBox(width: 80, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: CarbonColors.hairline),
                          
                          // Body
                          Expanded(
                            child: ListView.separated(
                              itemCount: () {
                                final int itemsPerPage = 10;
                                final int totalItems = filtered.length;
                                final int totalPages = (totalItems / itemsPerPage).ceil();
                                int page = _historyPage;
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
                                int page = _historyPage;
                                if (page > totalPages && totalPages > 0) {
                                  page = totalPages;
                                }
                                final int startIndex = (page - 1) * itemsPerPage;
                                final int endIndex = startIndex + itemsPerPage;
                                final paginatedList = filtered.sublist(
                                  startIndex,
                                  endIndex > totalItems ? totalItems : endIndex,
                                );
                                
                                final p = paginatedList[idx];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 3, child: Text(p['pencairan_id'] ?? '')),
                                      Expanded(flex: 2, child: Text(p['tanggal'] ?? '')),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '${p['anggota_nama']}\n(${p['anggota_id']})',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Expanded(flex: 2, child: Text('${p['total_berat']} Kg')),
                                      Expanded(flex: 2, child: Text(PrinterService.formatCurrency(p['total_pinjaman_dipotong'] ?? 0))),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          PrinterService.formatCurrency(p['total_netto'] ?? 0),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: CarbonColors.success),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: Tooltip(
                                          message: 'Cetak Ulang Struk',
                                          child: IconButton(
                                            icon: const Icon(Icons.print, color: CarbonColors.primary, size: 20),
                                            onPressed: () async {
                                              try {
                                                final weighings = await state.getPayoutWeighings(p['pencairan_id']);
                                                await PrinterService.printPayoutPdf(
                                                  namaAnggota: p['anggota_nama'] ?? 'Tidak Diketahui',
                                                  anggotaId: p['anggota_id'],
                                                  tanggalPayout: p['tanggal'],
                                                  payoutId: p['pencairan_id'],
                                                  weighings: weighings,
                                                  totalBerat: p['total_berat'],
                                                  totalBruto: p['total_bruto'],
                                                  totalAdm: p['total_adm'],
                                                  totalTrs: p['total_trs'],
                                                  pinjamanDipotong: p['total_pinjaman_dipotong'],
                                                  totalNetto: p['total_netto'],
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Gagal mencetak ulang struk: $e')),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          // Pagination
                          TablePagination(
                            currentPage: () {
                              final int itemsPerPage = 10;
                              final int totalItems = filtered.length;
                              final int totalPages = (totalItems / itemsPerPage).ceil();
                              int page = _historyPage;
                              if (page > totalPages && totalPages > 0) {
                                page = totalPages;
                              }
                              return page;
                            }(),
                            totalItems: filtered.length,
                            itemsPerPage: 10,
                            onPageChanged: (newPage) {
                              setState(() {
                                _historyPage = newPage;
                              });
                            },
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? textColor,
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: textColor,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style.copyWith(color: isBold ? null : CarbonColors.ink.withOpacity(0.7))),
          Text(value, style: style),
        ],
      ),
    );
  }
}

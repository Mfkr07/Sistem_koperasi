import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/constants/strings.dart';
import '../providers/app_state_provider.dart';
import '../core/services/printer_service.dart';
import '../widgets/table_pagination.dart';

class PinjamanScreen extends StatefulWidget {
  const PinjamanScreen({super.key});

  @override
  State<PinjamanScreen> createState() => _PinjamanScreenState();
}

class _PinjamanScreenState extends State<PinjamanScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedAnggotaId;
  String _searchQuery = '';
  final _jumlahController = TextEditingController();
  final _keteranganController = TextEditingController();

  // Selected member for view history
  String? _viewAnggotaId;
  String _searchQueryView = '';
  int _currentPage = 1;

  @override
  void dispose() {
    _jumlahController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    final filteredSearchCreate = state.anggotaList.where((a) {
      return a.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             a.anggotaId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredSearchView = state.anggotaList.where((a) {
      return a.nama.toLowerCase().contains(_searchQueryView.toLowerCase()) ||
             a.anggotaId.toLowerCase().contains(_searchQueryView.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: CarbonColors.canvas,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column: Search & View Member Loan History
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Histori & Saldo Pinjaman Petani',
                    style: CarbonTypography.headline.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Search Member to View
                  Text('Pilih Petani untuk Melihat Histori', style: CarbonTypography.caption),
                  const SizedBox(height: 8),
                  if (_viewAnggotaId == null) ...[
                    TextField(
                      onChanged: (val) => setState(() {
                        _searchQueryView = val;
                        _currentPage = 1;
                      }),
                      decoration: const InputDecoration(
                        hintText: 'Cari nama petani...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        fillColor: CarbonColors.surface1,
                        filled: true,
                        isDense: true,
                      ),
                    ),
                    if (_searchQueryView.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(border: Border.all(color: CarbonColors.hairline)),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredSearchView.length,
                          itemBuilder: (c, idx) {
                            final a = filteredSearchView[idx];
                            return ListTile(
                              dense: true,
                              title: Text(a.nama),
                              subtitle: Text(a.anggotaId),
                              onTap: () => setState(() {
                                _viewAnggotaId = a.anggotaId;
                                _searchQueryView = '';
                                _currentPage = 1;
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: CarbonColors.surface2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            state.anggotaList.firstWhere((m) => m.anggotaId == _viewAnggotaId).nama,
                            style: CarbonTypography.bodyEmphasis.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: CarbonColors.error),
                            onPressed: () => setState(() {
                              _viewAnggotaId = null;
                              _currentPage = 1;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // History Log
                  Expanded(
                    child: _viewAnggotaId == null
                        ? FutureBuilder<List<Map<String, dynamic>>>(
                            future: state.getAllPinjaman(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              // Filter by search query if any
                              final query = _searchQueryView.toLowerCase();
                              final allLoans = snapshot.data!.where((loan) {
                                final name = (loan['anggota_nama'] ?? '').toString().toLowerCase();
                                final memberId = loan['anggota_id'].toString().toLowerCase();
                                final loanId = loan['pinjaman_id'].toString().toLowerCase();
                                return name.contains(query) || memberId.contains(query) || loanId.contains(query);
                              }).toList();

                              if (allLoans.isEmpty) {
                                return const Center(child: Text('Tidak ada data pinjaman.'));
                              }

                              final int itemsPerPage = 10;
                              final int totalItems = allLoans.length;
                              final int totalPages = (totalItems / itemsPerPage).ceil();
                              int page = _currentPage;
                              if (page > totalPages && totalPages > 0) {
                                page = totalPages;
                              }
                              final int startIndex = (page - 1) * itemsPerPage;
                              final int endIndex = startIndex + itemsPerPage;
                              final paginatedLoans = allLoans.sublist(
                                startIndex,
                                endIndex > totalItems ? totalItems : endIndex,
                              );

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Semua Pinjaman Koperasi',
                                          style: CarbonTypography.bodyEmphasis.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Total: ${allLoans.length} records',
                                          style: CarbonTypography.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: CarbonColors.hairline),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(border: Border.all(color: CarbonColors.hairline)),
                                      child: ListView.separated(
                                        itemCount: paginatedLoans.length,
                                        separatorBuilder: (c, i) => const Divider(height: 1, color: CarbonColors.hairline),
                                        itemBuilder: (c, idx) {
                                          final l = paginatedLoans[idx];
                                          final status = l['status'] as String;
                                          final nama = l['anggota_nama'] ?? 'Tidak Diketahui';
                                          return ListTile(
                                            tileColor: CarbonColors.canvas,
                                            title: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '$nama (${l['anggota_id']})',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'ID: ${l['pinjaman_id']}',
                                                  style: CarbonTypography.caption,
                                                ),
                                              ],
                                            ),
                                            subtitle: Text(
                                              'Pinjam: ${l['tanggal_pinjam']} • Pokok: ${PrinterService.formatCurrency(l['jumlah_pokok'])} • Sisa: ${PrinterService.formatCurrency(l['saldo_sisa'])}\nKet: ${l['keterangan'] ?? '-'}'
                                            ),
                                            trailing: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              color: status == 'LUNAS' ? CarbonColors.success.withOpacity(0.1) : CarbonColors.warning.withOpacity(0.1),
                                              child: Text(
                                                status,
                                                style: CarbonTypography.caption.copyWith(
                                                  color: status == 'LUNAS' ? CarbonColors.success : CarbonColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  TablePagination(
                                    currentPage: page,
                                    totalItems: totalItems,
                                    itemsPerPage: itemsPerPage,
                                    onPageChanged: (newPage) {
                                      setState(() {
                                        _currentPage = newPage;
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          )
                        : FutureBuilder<List<Map<String, dynamic>>>(
                            future: state.getHistoriPinjaman(_viewAnggotaId!),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final list = snapshot.data!;
                              if (list.isEmpty) {
                                return const Center(child: Text('Anggota ini tidak memiliki riwayat pinjaman.'));
                              }

                              final int itemsPerPage = 10;
                              final int totalItems = list.length;
                              final int totalPages = (totalItems / itemsPerPage).ceil();
                              int page = _currentPage;
                              if (page > totalPages && totalPages > 0) {
                                page = totalPages;
                              }
                              final int startIndex = (page - 1) * itemsPerPage;
                              final int endIndex = startIndex + itemsPerPage;
                              final paginatedList = list.sublist(
                                startIndex,
                                endIndex > totalItems ? totalItems : endIndex,
                              );

                              return Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(border: Border.all(color: CarbonColors.hairline)),
                                      child: ListView.separated(
                                        itemCount: paginatedList.length,
                                        separatorBuilder: (c, i) => const Divider(height: 1, color: CarbonColors.hairline),
                                        itemBuilder: (c, idx) {
                                          final l = paginatedList[idx];
                                          final status = l['status'] as String;
                                          return ListTile(
                                            tileColor: CarbonColors.canvas,
                                            title: Text('Pinjaman ID: ${l['pinjaman_id']}'),
                                            subtitle: Text(
                                              'Pinjam: ${l['tanggal_pinjam']} • ${l['keterangan'] ?? ''}\nSisa Saldo: ${PrinterService.formatCurrency(l['saldo_sisa'])}'
                                            ),
                                            trailing: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              color: status == 'LUNAS' ? CarbonColors.success.withOpacity(0.1) : CarbonColors.warning.withOpacity(0.1),
                                              child: Text(
                                                status,
                                                style: CarbonTypography.caption.copyWith(
                                                  color: status == 'LUNAS' ? CarbonColors.success : CarbonColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  TablePagination(
                                    currentPage: page,
                                    totalItems: totalItems,
                                    itemsPerPage: itemsPerPage,
                                    onPageChanged: (newPage) {
                                      setState(() {
                                        _currentPage = newPage;
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),

            // Right Column: Form Panel (Add New Loan)
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: CarbonColors.surface1,
                      border: Border.all(color: CarbonColors.hairline, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pendaftaran Pinjaman Baru',
                          style: CarbonTypography.bodyEmphasis.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),

                        // Search Member to Create
                        Text('Pilih Penerima Pinjaman', style: CarbonTypography.caption),
                        const SizedBox(height: 8),
                        if (_selectedAnggotaId == null) ...[
                          TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: const InputDecoration(
                              hintText: 'Cari nama petani...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                              fillColor: CarbonColors.canvas,
                              filled: true,
                              isDense: true,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 180),
                              decoration: BoxDecoration(border: Border.all(color: CarbonColors.hairline)),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredSearchCreate.length,
                                itemBuilder: (c, idx) {
                                  final a = filteredSearchCreate[idx];
                                  return ListTile(
                                    dense: true,
                                    title: Text(a.nama),
                                    subtitle: Text(a.anggotaId),
                                    onTap: () => setState(() {
                                      _selectedAnggotaId = a.anggotaId;
                                      _searchQuery = '';
                                    }),
                                  );
                                },
                              ),
                            ),
                          ],
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: CarbonColors.surface2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  state.anggotaList.firstWhere((m) => m.anggotaId == _selectedAnggotaId).nama,
                                  style: CarbonTypography.bodyEmphasis.copyWith(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: CarbonColors.error),
                                  onPressed: () => setState(() => _selectedAnggotaId = null),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Jumlah Pokok
                        Text('Jumlah Pokok Pinjaman (Rp.)', style: CarbonTypography.caption),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _jumlahController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            fillColor: CarbonColors.canvas,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                            hintText: 'Contoh: 500000',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Keterangan
                        Text('Keterangan Pinjaman', style: CarbonTypography.caption),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _keteranganController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            fillColor: CarbonColors.canvas,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                            hintText: 'Contoh: Pinjaman pupuk / bibit',
                          ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (_selectedAnggotaId == null || _jumlahController.text.isEmpty)
                                    ? null
                                    : () async {
                                        final nominal = int.tryParse(_jumlahController.text);
                                        if (nominal != null && nominal > 0) {
                                          await state.tambahPinjaman(
                                            _selectedAnggotaId!,
                                            nominal,
                                            _keteranganController.text.isEmpty ? null : _keteranganController.text,
                                          );

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Pinjaman baru berhasil didaftarkan.')),
                                          );

                                          setState(() {
                                            _selectedAnggotaId = null;
                                            _jumlahController.clear();
                                            _keteranganController.clear();
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CarbonColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                child: Text(
                                  'DAFTARKAN PINJAMAN',
                                  style: CarbonTypography.button.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

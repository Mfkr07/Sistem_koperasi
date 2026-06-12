import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/constants/strings.dart';
import '../providers/app_state_provider.dart';
import '../core/services/kalkulasi_service.dart';
import '../core/services/printer_service.dart';

class FormTimbangScreen extends StatefulWidget {
  const FormTimbangScreen({super.key});

  @override
  State<FormTimbangScreen> createState() => _FormTimbangScreenState();
}

class _FormTimbangScreenState extends State<FormTimbangScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _anggotaId1;
  String? _anggotaId2;
  bool _isKepemilikanBersama = false;

  final _beratController = TextEditingController();
  
  // Porsi percentage
  double _porsi1 = 50.0;
  double _porsi2 = 50.0;

  // Selected loan ids ('FIFO' or specific pinjaman_id)
  String _selectedLoanId1 = 'FIFO';
  String _selectedLoanId2 = 'FIFO';

  // Loan deduction amounts
  final _potongController1 = TextEditingController(text: '0');
  final _potongController2 = TextEditingController(text: '0');

  // Member lists for dropdown searches
  String _searchQuery1 = '';
  String _searchQuery2 = '';

  @override
  void dispose() {
    _beratController.dispose();
    _potongController1.dispose();
    _potongController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    if (state.activeSesi == null) {
      return Scaffold(
        backgroundColor: CarbonColors.canvas,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_outlined, size: 64, color: CarbonColors.warning),
              const SizedBox(height: 24),
              Text(
                'Tidak Ada Sesi Timbang Aktif',
                style: CarbonTypography.subhead.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Silakan buka sesi timbang baru terlebih dahulu di menu Sesi Timbang.',
                style: CarbonTypography.caption,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => state.setScreen('sesi_timbang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CarbonColors.primary,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: const Text('Buka Sesi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final activeSesi = state.activeSesi!;

    // Perform live calculations
    final int beratTotal = int.tryParse(_beratController.text) ?? 0;
    final int potong1 = int.tryParse(_potongController1.text) ?? 0;
    final int potong2 = int.tryParse(_potongController2.text) ?? 0;

    // Filter members based on search
    final filteredMembers1 = state.anggotaList.where((a) {
      return a.nama.toLowerCase().contains(_searchQuery1.toLowerCase()) || 
             a.anggotaId.toLowerCase().contains(_searchQuery1.toLowerCase());
    }).toList();

    final filteredMembers2 = state.anggotaList.where((a) {
      return a.nama.toLowerCase().contains(_searchQuery2.toLowerCase()) || 
             a.anggotaId.toLowerCase().contains(_searchQuery2.toLowerCase());
    }).toList();

    // Primary owner calculation
    int weightPart1 = beratTotal;
    int weightPart2 = 0;
    if (_isKepemilikanBersama) {
      final parts = KalkulasiService.hitungBeratPorsiBersama(beratTotal, _porsi1, _porsi2);
      weightPart1 = parts[0];
      weightPart2 = parts[1];
    }

    final member1 = _anggotaId1 != null
        ? state.anggotaList.firstWhere((a) => a.anggotaId == _anggotaId1)
        : null;

    final member2 = (_isKepemilikanBersama && _anggotaId2 != null)
        ? state.anggotaList.firstWhere((a) => a.anggotaId == _anggotaId2)
        : null;

    final calc1 = KalkulasiService.hitung(
      beratTotal: beratTotal,
      porsiPersen: _isKepemilikanBersama ? _porsi1 : 100.0,
      hargaPerKg: activeSesi.hargaPerKg,
      tarifAdm: activeSesi.tarifAdmPerKg,
      tarifTrsDusun: activeSesi.tarifTrsDusun,
      tarifTrsIbol: activeSesi.tarifTrsIbol,
      tipeAngkutan: member1?.tipeAngkutan ?? 'SENDIRI',
      pinjamanDipotong: potong1,
      customBeratPorsi: weightPart1,
    );

    KalkulasiResult? calc2;
    if (_isKepemilikanBersama && member2 != null) {
      calc2 = KalkulasiService.hitung(
        beratTotal: beratTotal,
        porsiPersen: _porsi2,
        hargaPerKg: activeSesi.hargaPerKg,
        tarifAdm: activeSesi.tarifAdmPerKg,
        tarifTrsDusun: activeSesi.tarifTrsDusun,
        tarifTrsIbol: activeSesi.tarifTrsIbol,
        tipeAngkutan: member2.tipeAngkutan,
        pinjamanDipotong: potong2,
        customBeratPorsi: weightPart2,
      );
    }

    // Generate plain-text receipts for emulator preview
    final previewText1 = member1 != null
        ? PrinterService.generateTextReceipt(
            namaAnggota: member1.nama,
            beratTotal: beratTotal,
            porsiPersen: _isKepemilikanBersama ? _porsi1 : 100.0,
            beratPorsi: weightPart1,
            hargaPerKg: activeSesi.hargaPerKg,
            hargaBruto: calc1.hargaBruto,
            biayaAdm: calc1.biayaAdm,
            biayaTrs: calc1.biayaTrs,
            pinjamanDipotong: calc1.pinjamanDipotong,
            totalPotongan: calc1.totalPotongan,
            jumlahDibayar: calc1.jumlahDisetor,
            tanggalSesi: activeSesi.tanggal,
            noStruk: 'PREVIEW-001',
            tipeAngkutan: member1.tipeAngkutan,
            tarifAdm: activeSesi.tarifAdmPerKg,
          )
        : 'Silakan pilih Anggota untuk melihat pratinjau struk.';

    final previewText2 = (member2 != null && calc2 != null)
        ? PrinterService.generateTextReceipt(
            namaAnggota: member2.nama,
            beratTotal: beratTotal,
            porsiPersen: _porsi2,
            beratPorsi: weightPart2,
            hargaPerKg: activeSesi.hargaPerKg,
            hargaBruto: calc2.hargaBruto,
            biayaAdm: calc2.biayaAdm,
            biayaTrs: calc2.biayaTrs,
            pinjamanDipotong: calc2.pinjamanDipotong,
            totalPotongan: calc2.totalPotongan,
            jumlahDibayar: calc2.jumlahDisetor,
            tanggalSesi: activeSesi.tanggal,
            noStruk: 'PREVIEW-002',
            tipeAngkutan: member2.tipeAngkutan,
            tarifAdm: activeSesi.tarifAdmPerKg,
          )
        : 'Silakan pilih Anggota Kedua untuk melihat pratinjau struk.';

    return Scaffold(
      backgroundColor: CarbonColors.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column: Entry Form
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input Hasil Timbangan',
                      style: CarbonTypography.headline.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // Weight Input
                    Text('Berat Total (Kg)', style: CarbonTypography.caption),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _beratController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 156',
                        fillColor: CarbonColors.surface1,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Member 1 Selector
                    Text('Pilih Anggota / Petani', style: CarbonTypography.caption),
                    const SizedBox(height: 8),
                    _buildMemberSearchField(
                      query: _searchQuery1,
                      onSearchChanged: (val) => setState(() => _searchQuery1 = val),
                      selectedId: _anggotaId1,
                      filteredMembers: filteredMembers1,
                      onSelected: (id) async {
                        setState(() {
                          _anggotaId1 = id;
                          _searchQuery1 = '';
                          _selectedLoanId1 = 'FIFO';
                          _potongController1.text = '0';
                        });
                      },
                    ),
                    
                    if (member1 != null) ...[
                      const SizedBox(height: 12),
                      _buildLoanSelectionWidget(
                        state: state,
                        anggotaId: member1.anggotaId,
                        selectedLoanId: _selectedLoanId1,
                        potongController: _potongController1,
                        onLoanChanged: (val) => setState(() {
                          _selectedLoanId1 = val ?? 'FIFO';
                          _potongController1.text = '0';
                        }),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Joint Ownership Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _isKepemilikanBersama,
                          activeColor: CarbonColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _isKepemilikanBersama = val ?? false;
                              if (!_isKepemilikanBersama) {
                                _anggotaId2 = null;
                                _selectedLoanId2 = 'FIFO';
                                _potongController2.text = '0';
                              }
                            });
                          },
                        ),
                        Text(
                          'Kepemilikan Bersama (Bagi Porsi Struk)',
                          style: CarbonTypography.bodySm.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    if (_isKepemilikanBersama) ...[
                      const SizedBox(height: 20),
                      Text('Pembagian Porsi (%)', style: CarbonTypography.caption),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPorsiSelector(50, 50, 'Porsi Seimbang 50/50'),
                          const SizedBox(width: 16),
                          _buildPorsiSelector(60, 40, 'Porsi 60/40'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Member 2 Selector
                      Text('Pilih Anggota Kedua', style: CarbonTypography.caption),
                      const SizedBox(height: 8),
                      _buildMemberSearchField(
                        query: _searchQuery2,
                        onSearchChanged: (val) => setState(() => _searchQuery2 = val),
                        selectedId: _anggotaId2,
                        filteredMembers: filteredMembers2,
                        onSelected: (id) {
                          setState(() {
                            _anggotaId2 = id;
                            _searchQuery2 = '';
                            _selectedLoanId2 = 'FIFO';
                            _potongController2.text = '0';
                          });
                        },
                      ),
                      if (member2 != null) ...[
                        const SizedBox(height: 12),
                        _buildLoanSelectionWidget(
                          state: state,
                          anggotaId: member2.anggotaId,
                          selectedLoanId: _selectedLoanId2,
                          potongController: _potongController2,
                          onLoanChanged: (val) => setState(() {
                            _selectedLoanId2 = val ?? 'FIFO';
                            _potongController2.text = '0';
                          }),
                        ),
                      ],
                    ],

                    const SizedBox(height: 40),
                    
                    // Action Buttons
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: (member1 == null || (beratTotal <= 0))
                              ? null
                              : () async {
                                  await state.simpanTransaksi(
                                    anggotaId1: _anggotaId1!,
                                    anggotaId2: _anggotaId2,
                                    beratTotal: beratTotal,
                                    porsi1: _porsi1,
                                    porsi2: _porsi2,
                                    pinjamanDipotong1: potong1,
                                    pinjamanDipotong2: potong2,
                                    selectedPinjamanId1: _selectedLoanId1,
                                    selectedPinjamanId2: _selectedLoanId2,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Transaksi timbang berhasil disimpan.')),
                                  );

                                  // Reset Form
                                  setState(() {
                                    _beratController.clear();
                                    _anggotaId1 = null;
                                    _anggotaId2 = null;
                                    _isKepemilikanBersama = false;
                                    _potongController1.text = '0';
                                    _potongController2.text = '0';
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CarbonColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: Text(
                            'SIMPAN TRANSAKSI & CETAK',
                            style: CarbonTypography.button.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Right Column: Thermal Receipt Emulator Preview
          Expanded(
            flex: 5,
            child: Container(
              color: CarbonColors.surface1,
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Virtual Thermal Print Preview',
                    style: CarbonTypography.subhead.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  // Receipt Paper view
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFF4), // Slight yellow-tinted thermal paper look
                        border: Border.all(color: CarbonColors.hairline, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Text(
                          _isKepemilikanBersama
                              ? '=== STRUK 1 (PEMILIK A) ===\n\n$previewText1\n\n=== STRUK 2 (PEMILIK B) ===\n\n$previewText2'
                              : previewText1,
                          style: const TextStyle(
                            fontFamily: 'Courier', // Standard system Courier font
                            fontSize: 12,
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
      ),
    );
  }

  Widget _buildMemberSearchField({
    required String query,
    required ValueChanged<String> onSearchChanged,
    required String? selectedId,
    required List<dynamic> filteredMembers,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedId == null) ...[
          TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Cari nama atau ID petani...',
              prefixIcon: Icon(Icons.search, size: 20),
              fillColor: CarbonColors.surface1,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              isDense: true,
            ),
          ),
          if (query.isNotEmpty) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                border: Border.all(color: CarbonColors.hairline),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredMembers.length,
                itemBuilder: (c, idx) {
                  final member = filteredMembers[idx];
                  return ListTile(
                    dense: true,
                    title: Text(member.nama),
                    subtitle: Text('${member.anggotaId} • ${member.tipeAngkutan}'),
                    onTap: () => onSelected(member.anggotaId),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filteredMembers.firstWhere((m) => m.anggotaId == selectedId).nama,
                      style: CarbonTypography.bodyEmphasis.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$selectedId • Angkutan: ${filteredMembers.firstWhere((m) => m.anggotaId == selectedId).tipeAngkutan}',
                      style: CarbonTypography.caption,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: CarbonColors.error),
                  onPressed: () => setState(() {
                    if (selectedId == _anggotaId1) {
                      _anggotaId1 = null;
                    } else {
                      _anggotaId2 = null;
                    }
                  }),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoanSelectionWidget({
    required AppStateProvider state,
    required String anggotaId,
    required String selectedLoanId,
    required TextEditingController potongController,
    required ValueChanged<String?> onLoanChanged,
  }) {
    // Find active loans
    final loans = state.sessions.isEmpty ? <Map<String, dynamic>>[] : []; // we fetch loans below
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: state.getHistoriPinjaman(anggotaId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final activeLoans = snapshot.data!.where((l) => l['status'] == 'AKTIF').toList();
        if (activeLoans.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Tidak memiliki pinjaman aktif.',
              style: CarbonTypography.caption.copyWith(color: CarbonColors.success),
            ),
          );
        }

        int totalSisaLoans = 0;
        for (var loan in activeLoans) {
          totalSisaLoans += (loan['saldo_sisa'] as num).toInt();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilihan Pemotongan Pinjaman (Total Aktif: ${PrinterService.formatCurrency(totalSisaLoans)})',
                        style: CarbonTypography.caption,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedLoanId,
                        onChanged: onLoanChanged,
                        decoration: const InputDecoration(
                          fillColor: CarbonColors.canvas,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: 'FIFO', child: Text('FIFO (Tertua Dahulu)')),
                          ...activeLoans.map((l) {
                            return DropdownMenuItem(
                              value: l['pinjaman_id'] as String,
                              child: Text(
                                'Deduct ${l['pinjaman_id']} (Saldo: ${PrinterService.formatCurrency(l['saldo_sisa'])})'
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jumlah Potong Rp', style: CarbonTypography.caption),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: potongController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setState(() {}),
                        decoration: const InputDecoration(
                          fillColor: CarbonColors.canvas,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPorsiSelector(double p1, double p2, String label) {
    bool active = _porsi1 == p1;
    return InkWell(
      onTap: () {
        setState(() {
          _porsi1 = p1;
          _porsi2 = p2;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? CarbonColors.primary : Colors.transparent,
          border: Border.all(color: CarbonColors.ink, width: 1),
        ),
        child: Text(
          label,
          style: CarbonTypography.caption.copyWith(
            color: active ? CarbonColors.onPrimary : CarbonColors.ink,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

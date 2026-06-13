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

  // Selected transport rates
  int _transportFee1 = 0;
  int _transportFee2 = 0;

  // Member lists for dropdown searches
  String _searchQuery1 = '';
  String _searchQuery2 = '';

  @override
  void dispose() {
    _beratController.dispose();
    super.dispose();
  }

  Widget _buildTransportFeeSelector(int selectedValue, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tarif Transportasi (per Kg)', style: CarbonTypography.caption),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildOptionButton(0, 'Mandiri (Rp 0)', selectedValue, onChanged),
            const SizedBox(width: 8),
            _buildOptionButton(100, 'Transport (Rp 100)', selectedValue, onChanged),
            const SizedBox(width: 8),
            _buildOptionButton(350, 'Transport (Rp 350)', selectedValue, onChanged),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton(int value, String label, int selectedValue, ValueChanged<int> onChanged) {
    final bool isSelected = value == selectedValue;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? CarbonColors.primary : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : CarbonColors.ink,
          side: BorderSide(
            color: isSelected ? CarbonColors.primary : CarbonColors.hairline,
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        onPressed: () => onChanged(value),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
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
    final int beratTotal = int.tryParse(_beratController.text) ?? 0;

    final filteredMembers1 = state.anggotaList.where((a) {
      return a.nama.toLowerCase().contains(_searchQuery1.toLowerCase()) || 
             a.anggotaId.toLowerCase().contains(_searchQuery1.toLowerCase());
    }).toList();

    final filteredMembers2 = state.anggotaList.where((a) {
      return a.nama.toLowerCase().contains(_searchQuery2.toLowerCase()) || 
             a.anggotaId.toLowerCase().contains(_searchQuery2.toLowerCase());
    }).toList();

    final member1 = _anggotaId1 != null
        ? state.anggotaList.firstWhere((a) => a.anggotaId == _anggotaId1)
        : null;

    return Scaffold(
      backgroundColor: CarbonColors.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: CarbonColors.surface1,
              border: Border.all(color: CarbonColors.hairline, width: 1),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Input Hasil Timbangan Karet',
                    style: CarbonTypography.headline.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sesi: ${activeSesi.tanggal} • Harga: Rp ${activeSesi.hargaPerKg}/Kg',
                    style: CarbonTypography.caption,
                  ),
                  const SizedBox(height: 32),

                  // Weight Input
                  Text('Berat Total (Kg)', style: CarbonTypography.caption),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _beratController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 156',
                      fillColor: CarbonColors.canvas,
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
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Transport Selector 1
                  if (_anggotaId1 != null) ...[
                    _buildTransportFeeSelector(
                      _transportFee1,
                      (val) => setState(() => _transportFee1 = val),
                    ),
                    const SizedBox(height: 24),
                  ],

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
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Transport Selector 2
                    if (_anggotaId2 != null) ...[
                      _buildTransportFeeSelector(
                        _transportFee2,
                        (val) => setState(() => _transportFee2 = val),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],

                  const SizedBox(height: 40),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (member1 == null || (beratTotal <= 0))
                          ? null
                          : () async {
                              await state.simpanTransaksi(
                                anggotaId1: _anggotaId1!,
                                anggotaId2: _anggotaId2,
                                beratTotal: beratTotal,
                                porsi1: _porsi1,
                                porsi2: _porsi2,
                                tarifTransport1: _transportFee1,
                                tarifTransport2: _transportFee2,
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
                                _transportFee1 = 0;
                                _transportFee2 = 0;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CarbonColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text(
                        'SIMPAN TRANSAKSI TIMBANG',
                        style: CarbonTypography.button.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
              fillColor: CarbonColors.canvas,
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
                color: CarbonColors.canvas,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredMembers.length,
                itemBuilder: (c, idx) {
                  final member = filteredMembers[idx];
                  return ListTile(
                    dense: true,
                    title: Text(member.nama),
                    subtitle: Text(member.anggotaId),
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
                      selectedId,
                      style: CarbonTypography.caption,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: CarbonColors.error),
                  onPressed: () => setState(() {
                    if (selectedId == _anggotaId1) {
                      _anggotaId1 = null;
                      _transportFee1 = 0;
                    } else {
                      _anggotaId2 = null;
                      _transportFee2 = 0;
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

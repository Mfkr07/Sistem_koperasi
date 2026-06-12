import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/constants/strings.dart';
import '../providers/app_state_provider.dart';
import '../models/anggota.dart';

class AnggotaScreen extends StatefulWidget {
  const AnggotaScreen({super.key});

  @override
  State<AnggotaScreen> createState() => _AnggotaScreenState();
}

class _AnggotaScreenState extends State<AnggotaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _searchQuery = '';
  Anggota? _editingAnggota;

  final _namaController = TextEditingController();
  final _noHpController = TextEditingController();
  String _tipeAngkutan = 'SENDIRI';
  String? _selectedKoorId;
  int _statusAktif = 1;

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  void _resetForm(AppStateProvider state) {
    setState(() {
      _editingAnggota = null;
      _namaController.clear();
      _noHpController.clear();
      _tipeAngkutan = 'SENDIRI';
      _statusAktif = 1;
      if (state.koordinators.isNotEmpty) {
        _selectedKoorId = state.koordinators.first.koordinatorId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    
    if (_selectedKoorId == null && state.koordinators.isNotEmpty) {
      _selectedKoorId = state.koordinators.first.koordinatorId;
    }

    final filtered = state.anggotaList.where((a) {
      return a.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             a.anggotaId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: CarbonColors.canvas,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Member List Table
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Anggota & Petani',
                    style: CarbonTypography.headline.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  // Search
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Cari anggota...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      fillColor: CarbonColors.surface1,
                      filled: true,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Table
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: CarbonColors.hairline, width: 1),
                      ),
                      child: filtered.isEmpty
                          ? const Center(child: Text('Tidak ada data anggota.'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (c, i) => const Divider(height: 1, color: CarbonColors.hairline),
                              itemBuilder: (c, idx) {
                                final a = filtered[idx];
                                final k = state.koordinators.firstWhere(
                                  (koor) => koor.koordinatorId == a.koordinatorId,
                                  orElse: () => state.koordinators.first,
                                );
                                
                                return ListTile(
                                  tileColor: CarbonColors.canvas,
                                  title: Text(a.nama),
                                  subtitle: Text('${a.anggotaId} • ${a.tipeAngkutan} • Koor: ${k.nama}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        color: a.statusAktif == 1 ? CarbonColors.success.withOpacity(0.1) : CarbonColors.error.withOpacity(0.1),
                                        child: Text(
                                          a.statusAktif == 1 ? 'AKTIF' : 'NON-AKTIF',
                                          style: CarbonTypography.caption.copyWith(
                                            color: a.statusAktif == 1 ? CarbonColors.success : CarbonColors.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _editingAnggota = a;
                                            _namaController.text = a.nama;
                                            _noHpController.text = a.noHp ?? '';
                                            _tipeAngkutan = a.tipeAngkutan;
                                            _selectedKoorId = a.koordinatorId;
                                            _statusAktif = a.statusAktif;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),

            // Right Column: Form Panel (Add / Edit)
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
                          _editingAnggota == null ? 'Registrasi Anggota Baru' : 'Edit Data Anggota',
                          style: CarbonTypography.bodyEmphasis.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),

                        // Nama
                        Text('Nama Anggota', style: CarbonTypography.caption),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _namaController,
                          decoration: const InputDecoration(
                            fillColor: CarbonColors.canvas,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tipe Angkutan
                        Text('Tipe Angkutan Default', style: CarbonTypography.caption),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _tipeAngkutan,
                          items: const [
                            DropdownMenuItem(value: 'SENDIRI', child: Text('SENDIRI (Rp. 0)')),
                            DropdownMenuItem(value: 'DUSUN', child: Text('DUSUN (Tarif Dusun)')),
                            DropdownMenuItem(value: 'IBOL', child: Text('IBOL (Tarif Ibol)')),
                          ],
                          onChanged: (val) => setState(() => _tipeAngkutan = val ?? 'SENDIRI'),
                          decoration: const InputDecoration(
                            fillColor: CarbonColors.canvas,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Koordinator (only editable on creation)
                        if (_editingAnggota == null) ...[
                          Text('Pilih Koordinator', style: CarbonTypography.caption),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedKoorId,
                            items: state.koordinators.map((k) {
                              return DropdownMenuItem(
                                value: k.koordinatorId,
                                child: Text(k.nama),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedKoorId = val),
                            decoration: const InputDecoration(
                              fillColor: CarbonColors.canvas,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // No HP
                        Text('Nomor HP (Opsional)', style: CarbonTypography.caption),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _noHpController,
                          decoration: const InputDecoration(
                            fillColor: CarbonColors.canvas,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Status (only editable on editing)
                        if (_editingAnggota != null) ...[
                          Text('Status Aktif', style: CarbonTypography.caption),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _statusAktif,
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('AKTIF')),
                              DropdownMenuItem(value: 0, child: Text('NON-AKTIF')),
                            ],
                            onChanged: (val) => setState(() => _statusAktif = val ?? 1),
                            decoration: const InputDecoration(
                              fillColor: CarbonColors.canvas,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_editingAnggota == null) {
                                    if (_selectedKoorId == null) return;
                                    await state.tambahAnggota(
                                      nama: _namaController.text,
                                      koordinatorId: _selectedKoorId!,
                                      tipeAngkutan: _tipeAngkutan,
                                      noHp: _noHpController.text.isEmpty ? null : _noHpController.text,
                                    );
                                  } else {
                                    await state.editAnggota(
                                      anggotaId: _editingAnggota!.anggotaId,
                                      nama: _namaController.text,
                                      tipeAngkutan: _tipeAngkutan,
                                      statusAktif: _statusAktif,
                                      noHp: _noHpController.text.isEmpty ? null : _noHpController.text,
                                    );
                                  }
                                  
                                  _resetForm(state);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Data Anggota berhasil disimpan.')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CarbonColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                child: Text(
                                  _editingAnggota == null ? 'TAMBAH ANGGOTA' : 'UPDATE ANGGOTA',
                                  style: CarbonTypography.button.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            if (_editingAnggota != null) ...[
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () => _resetForm(state),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: CarbonColors.ink,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                    side: BorderSide(color: CarbonColors.ink, width: 1),
                                  ),
                                ),
                                child: const Text('BATAL'),
                              ),
                            ],
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

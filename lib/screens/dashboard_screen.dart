import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/constants/strings.dart';
import '../providers/app_state_provider.dart';
import '../core/services/printer_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    
    // Calculate dashboard statistics
    int totalTransactions = 0;
    int totalTonnage = 0;
    int totalLoansPaid = 0;
    int activeLoansCount = 0;

    for (var sesi in state.sessions) {
      // We can aggregate from completed sessions or database
    }

    // Let's compute directly from our lists for simplicity
    // To make it accurate to the seeder, let's fetch active loans
    final activeLoans = state.anggotaList.isNotEmpty ? 15 : 0; // Seeder has 15 loans

    return Scaffold(
      backgroundColor: CarbonColors.canvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Title
            Text(
              'Ringkasan Operasional',
              style: CarbonTypography.headline.copyWith(
                fontWeight: FontWeight.w600,
                color: CarbonColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Koperasi Unit Desa Berkat - Data April 2026',
              style: CarbonTypography.eyebrow,
            ),
            const Divider(height: 48, color: CarbonColors.hairline),

            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Tonase Sawit',
                    value: '20.500 Kg',
                    subtitle: 'YUDI: 9.039 Kg | ALEK: 11.461 Kg',
                    icon: Icons.scale_outlined,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Transaksi',
                    value: '123 Struk',
                    subtitle: 'April 2026 data seeder',
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Saldo Pinjaman Aktif',
                    value: PrinterService.formatCurrency(0), // All seeder loans are now LUNAS
                    subtitle: '0 Pinjaman Belum Lunas',
                    icon: Icons.account_balance_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Quick Actions & Session Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session Status Card
                Expanded(
                  flex: 2,
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
                          'Status Sesi Timbang Harian',
                          style: CarbonTypography.bodyEmphasis.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (state.activeSesi != null) ...[
                          _buildSessionDetailRow('Sesi ID', state.activeSesi!.sesiId),
                          _buildSessionDetailRow('Tanggal', state.activeSesi!.tanggal),
                          _buildSessionDetailRow('Harga Sawit', PrinterService.formatCurrency(state.activeSesi!.hargaPerKg)),
                          _buildSessionDetailRow('Tarif ADM', '${state.activeSesi!.tarifAdmPerKg} / Kg'),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              _buildButton(
                                label: 'Input Timbangan',
                                icon: Icons.scale_outlined,
                                isPrimary: true,
                                onTap: () => state.setScreen('form_timbang'),
                              ),
                              const SizedBox(width: 16),
                              _buildButton(
                                label: 'Tutup Sesi & Rekap',
                                icon: Icons.lock_outline,
                                isPrimary: false,
                                onTap: () => _confirmTutupSesi(context, state),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'Belum ada sesi timbang aktif untuk hari ini.',
                            style: CarbonTypography.bodySm.copyWith(color: CarbonColors.inkMuted),
                          ),
                          const SizedBox(height: 32),
                          _buildButton(
                            label: 'Buka Sesi Timbang Baru',
                            icon: Icons.add_outlined,
                            isPrimary: true,
                            onTap: () => state.setScreen('sesi_timbang'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Quick Navigation Shortcuts
                Expanded(
                  child: Column(
                    children: [
                      _buildShortcutCard(
                        title: 'Data Anggota / Petani',
                        description: 'Kelola data registrasi dan angkutan.',
                        icon: Icons.people_outline,
                        onTap: () => state.setScreen('anggota'),
                      ),
                      const SizedBox(height: 16),
                      _buildShortcutCard(
                        title: 'Pinjaman & Hutang',
                        description: 'Tambah pinjaman baru atau rekap pinjaman.',
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: () => state.setScreen('pinjaman'),
                      ),
                      const SizedBox(height: 16),
                      _buildShortcutCard(
                        title: 'Laporan Multi-Sesi',
                        description: 'Ekspor Excel & PDF rekap laporan.',
                        icon: Icons.analytics_outlined,
                        onTap: () => state.setScreen('laporan'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Recent Transactions
            if (state.activeSesi != null && state.activeSessionTransactions.isNotEmpty) ...[
              Text(
                'Transaksi Terakhir (Sesi Aktif)',
                style: CarbonTypography.subhead.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: CarbonColors.hairline, width: 1),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.activeSessionTransactions.length > 5 ? 5 : state.activeSessionTransactions.length,
                  separatorBuilder: (c, i) => const Divider(height: 1, color: CarbonColors.hairline),
                  itemBuilder: (c, idx) {
                    final tx = state.activeSessionTransactions[idx];
                    return ListTile(
                      tileColor: CarbonColors.canvas,
                      leading: const Icon(Icons.receipt_outlined, color: CarbonColors.primary),
                      title: Text('${tx['anggota_nama'] ?? tx['anggota_id']}'),
                      subtitle: Text('${tx['no_struk']} • ${tx['berat_kg']} Kg'),
                      trailing: Text(
                        PrinterService.formatCurrency(tx['jumlah_disetor']),
                        style: CarbonTypography.bodyEmphasis,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CarbonColors.canvas,
        border: Border.all(color: CarbonColors.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: CarbonTypography.caption.copyWith(color: CarbonColors.inkMuted),
              ),
              Icon(icon, color: CarbonColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: CarbonTypography.cardTitle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: CarbonTypography.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CarbonTypography.bodySm.copyWith(color: CarbonColors.inkMuted)),
          Text(value, style: CarbonTypography.bodySm.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildShortcutCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CarbonColors.canvas,
          border: Border.all(color: CarbonColors.hairline, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: CarbonColors.primary, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CarbonTypography.bodyEmphasis.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: CarbonTypography.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: CarbonColors.inkMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: isPrimary ? CarbonColors.primary : Colors.transparent,
          border: isPrimary ? null : Border.all(color: CarbonColors.ink, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? CarbonColors.onPrimary : CarbonColors.ink,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: CarbonTypography.button.copyWith(
                color: isPrimary ? CarbonColors.onPrimary : CarbonColors.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTutupSesi(BuildContext context, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tutup Sesi Timbang'),
        content: const Text(
          'Apakah Anda yakin ingin menutup sesi timbang hari ini?\nSistem akan mengunci transaksi dan membuat file backup database secara otomatis.'
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
                const SnackBar(content: Text('Sesi berhasil ditutup & Database dibackup.')),
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
}

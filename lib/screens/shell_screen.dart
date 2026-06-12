import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/constants/strings.dart';
import '../providers/app_state_provider.dart';
import 'dashboard_screen.dart';
import 'sesi_timbang_screen.dart';
import 'form_timbang_screen.dart';
import 'anggota_screen.dart';
import 'pinjaman_screen.dart';
import 'laporan_screen.dart';
import 'pengaturan_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: CarbonColors.canvas,
        body: Center(
          child: CircularProgressIndicator(
            color: CarbonColors.primary,
          ),
        ),
      );
    }

    Widget currentWidget;
    switch (state.currentScreen) {
      case 'dashboard':
        currentWidget = const DashboardScreen();
        break;
      case 'sesi_timbang':
        currentWidget = const SesiTimbangScreen();
        break;
      case 'form_timbang':
        currentWidget = const FormTimbangScreen();
        break;
      case 'anggota':
        currentWidget = const AnggotaScreen();
        break;
      case 'pinjaman':
        currentWidget = const PinjamanScreen();
        break;
      case 'laporan':
        currentWidget = const LaporanScreen();
        break;
      case 'pengaturan':
        currentWidget = const PengaturanScreen();
        break;
      default:
        currentWidget = const DashboardScreen();
    }

    return Scaffold(
      backgroundColor: CarbonColors.canvas,
      body: Row(
        children: [
          // Sidebar (IBM Carbon Navigation)
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: CarbonColors.surface1,
              border: Border(
                right: BorderSide(color: CarbonColors.hairline, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: CarbonColors.hairline, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TPK Koperasi',
                        style: CarbonTypography.bodyEmphasis.copyWith(
                          fontSize: 20,
                          color: CarbonColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sawit KUD Berkat',
                        style: CarbonTypography.caption.copyWith(
                          color: CarbonColors.inkMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Navigation items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildSidebarItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        label: AppStrings.dashboard,
                        screenKey: 'dashboard',
                        isActive: state.currentScreen == 'dashboard',
                      ),
                      _buildSidebarItem(
                        context,
                        icon: Icons.timer_outlined,
                        label: AppStrings.sesiTimbang,
                        screenKey: 'sesi_timbang',
                        isActive: state.currentScreen == 'sesi_timbang',
                      ),
                      if (state.activeSesi != null)
                        _buildSidebarItem(
                          context,
                          icon: Icons.scale_outlined,
                          label: 'Input Timbangan',
                          screenKey: 'form_timbang',
                          isActive: state.currentScreen == 'form_timbang',
                          isSubItem: true,
                        ),
                      _buildSidebarItem(
                        context,
                        icon: Icons.people_outline,
                        label: 'Anggota & Petani',
                        screenKey: 'anggota',
                        isActive: state.currentScreen == 'anggota',
                      ),
                      _buildSidebarItem(
                        context,
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Pinjaman / Hutang',
                        screenKey: 'pinjaman',
                        isActive: state.currentScreen == 'pinjaman',
                      ),
                      _buildSidebarItem(
                        context,
                        icon: Icons.analytics_outlined,
                        label: 'Laporan & Rekap',
                        screenKey: 'laporan',
                        isActive: state.currentScreen == 'laporan',
                      ),
                      _buildSidebarItem(
                        context,
                        icon: Icons.settings_outlined,
                        label: AppStrings.pengaturan,
                        screenKey: 'pengaturan',
                        isActive: state.currentScreen == 'pengaturan',
                      ),
                    ],
                  ),
                ),

                // Active Session Status Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: CarbonColors.surface2,
                    border: Border(
                      top: BorderSide(color: CarbonColors.hairline, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: state.activeSesi != null ? CarbonColors.success : CarbonColors.inkSubtle,
                          shape: BoxShape.rectangle, // Strictly square corners
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.activeSesi != null ? 'Sesi Aktif' : 'Tidak Ada Sesi',
                              style: CarbonTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: CarbonColors.ink,
                              ),
                            ),
                            if (state.activeSesi != null)
                              Text(
                                state.activeSesi!.sesiId,
                                style: CarbonTypography.caption.copyWith(
                                  fontSize: 10,
                                  color: CarbonColors.inkMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main Panel Content
          Expanded(
            child: Container(
              color: CarbonColors.canvas,
              child: currentWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String screenKey,
    required bool isActive,
    bool isSubItem = false,
  }) {
    return InkWell(
      onTap: () {
        context.read<AppStateProvider>().setScreen(screenKey);
      },
      borderRadius: BorderRadius.zero, // IBM Carbon strictly flat square corners
      child: Container(
        height: 48,
        padding: EdgeInsets.only(left: isSubItem ? 36.0 : 20.0),
        decoration: BoxDecoration(
          color: isActive ? CarbonColors.surface2 : Colors.transparent,
          border: isActive
              ? const Border(
                  left: BorderSide(color: CarbonColors.primary, width: 4),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? CarbonColors.primary : CarbonColors.inkMuted,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: CarbonTypography.bodySm.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? CarbonColors.primary : CarbonColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

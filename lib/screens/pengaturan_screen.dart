import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/constants/strings.dart';
import '../providers/app_state_provider.dart';
import '../core/database/database_helper.dart';

class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: CarbonColors.canvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan & Pemeliharaan',
              style: CarbonTypography.headline.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Konfigurasi identitas koperasi dan pemeliharaan database SQLite.',
              style: CarbonTypography.caption,
            ),
            const Divider(height: 48, color: CarbonColors.hairline),

            // Cooperative Identity Settings
            Text(
              'Identitas Koperasi & TPK',
              style: CarbonTypography.subhead.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: CarbonColors.surface1,
                border: Border.all(color: CarbonColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama Koperasi: KUD BERKAT (Default)', style: CarbonTypography.bodyEmphasis),
                  const SizedBox(height: 8),
                  Text('Badan Hukum: No. 00292/BH/PAD KWK 6/VI/1996 Tgl. 3 Juli 1996', style: CarbonTypography.bodySm),
                  const SizedBox(height: 8),
                  Text('Nama TPK Unit: TPK Muara Ujanmas', style: CarbonTypography.bodySm),
                  const SizedBox(height: 16),
                  Text(
                    '*Catatan: Informasi identitas dicetak langsung di bagian header struk receipt sesuai format resmi.',
                    style: CarbonTypography.caption.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Database Actions
            Text(
              'Pemeliharaan Database',
              style: CarbonTypography.subhead.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: CarbonColors.surface1,
                border: Border.all(color: CarbonColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Backup
                  _buildMaintenanceAction(
                    context,
                    title: 'Backup Database Manual',
                    description: 'Salin file database aktif ke folder dokumen Anda sebagai cadangan aman.',
                    buttonLabel: 'CREATE BACKUP',
                    onTap: () => _triggerBackup(context),
                    disabled: kIsWeb,
                  ),
                  const Divider(height: 32, color: CarbonColors.hairline),

                  // Restore
                  _buildMaintenanceAction(
                    context,
                    title: 'Restore Database',
                    description: 'Impor file database TPK (.db) yang telah dicadangkan sebelumnya untuk memulihkan seluruh data.',
                    buttonLabel: 'RESTORE DATABASE',
                    onTap: () => _triggerRestore(context, state),
                    disabled: kIsWeb,
                  ),
                  const Divider(height: 32, color: CarbonColors.hairline),

                  // Reset
                  _buildMaintenanceAction(
                    context,
                    title: 'Reset Total Database',
                    description: 'Hapus seluruh data transaksi, pinjaman, dan sesi. Berguna untuk memulai pembukuan periode baru.',
                    buttonLabel: 'RESET DATABASE',
                    onTap: () => _confirmReset(context, state),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceAction(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool disabled = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: CarbonTypography.bodyEmphasis.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                disabled ? '$description (Fitur ini hanya didukung pada aplikasi desktop Windows)' : description,
                style: CarbonTypography.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        ElevatedButton(
          onPressed: (disabled) ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? CarbonColors.error : CarbonColors.primary,
            disabledBackgroundColor: CarbonColors.surface2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Text(
            buttonLabel,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _triggerBackup(BuildContext context) async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'TPK_Koperasi', 'data.db');
      
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: File database tidak ditemukan.')),
        );
        return;
      }

      String? selectedFolder = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih Folder Simpan Backup',
      );

      if (selectedFolder != null) {
        final timestamp = DateTime.now().toIso8601String().split('T')[0].replaceAll('-', '');
        final destination = p.join(selectedFolder, 'TPK_Manual_Backup_$timestamp.db');
        await dbFile.copy(destination);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup berhasil disimpan ke: $destination')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal melakukan backup: $e')),
      );
    }
  }

  Future<void> _triggerRestore(BuildContext context, AppStateProvider state) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Pilih File Database Backup (.db)',
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final backupFile = File(result.files.single.path!);
        
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbPath = p.join(dbFolder.path, 'TPK_Koperasi', 'data.db');
        
        // Close database before replacing it
        await DatabaseHelper.instance.closeDatabase();
        
        // Overwrite active database file
        await backupFile.copy(dbPath);
        
        // Reinitialize app state
        await state.initApp();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database berhasil dipulihkan dari file backup.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memulihkan database: $e')),
      );
    }
  }

  void _confirmReset(BuildContext context, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset Total Database'),
        content: const Text(
          'TINDAKAN INI BERBAHAYA!\nSeluruh transaksi, pinjaman, dan sesi akan dihapus secara permanen. Koperasi akan kembali ke status kosong/awal seeder.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal', style: TextStyle(color: CarbonColors.ink)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              await state.clearDatabase();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database berhasil direset.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CarbonColors.error,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('RESET', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

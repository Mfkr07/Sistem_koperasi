import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/database/database_helper.dart';
import '../core/database/seed_data_parser.dart';
import '../core/services/kalkulasi_service.dart';
import '../models/koordinator.dart';
import '../models/anggota.dart';
import '../models/sesi_timbang.dart';
import '../models/transaksi.dart';
import '../models/pinjaman.dart';
import '../models/pengeluaran.dart';

class AppStateProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Koordinator> _koordinators = [];
  List<Koordinator> get koordinators => _koordinators;

  List<Anggota> _anggotaList = [];
  List<Anggota> get anggotaList => _anggotaList;

  List<SesiTimbang> _sessions = [];
  List<SesiTimbang> get sessions => _sessions;

  SesiTimbang? _activeSesi;
  SesiTimbang? get activeSesi => _activeSesi;

  List<Map<String, dynamic>> _activeSessionTransactions = [];
  List<Map<String, dynamic>> get activeSessionTransactions => _activeSessionTransactions;

  List<Map<String, dynamic>> _activeSessionExpenses = [];
  List<Map<String, dynamic>> get activeSessionExpenses => _activeSessionExpenses;

  // Navigation state
  String _currentScreen = 'dashboard';
  String get currentScreen => _currentScreen;

  void setScreen(String screenName) {
    _currentScreen = screenName;
    notifyListeners();
  }

  /// Initialize application, database, and seed data
  Future<void> initApp() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Trigger DB initialization
      await _dbHelper.database;
      
      // Parse seeder data if empty
      await SeedDataParser.seedDatabase();

      // Load initial lists
      await refreshData();
    } catch (e) {
      if (kDebugMode) print("Initialization error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload all records from local DB
  Future<void> refreshData() async {
    await fetchCoordinators();
    await fetchMembers();
    await fetchSessions();
    await checkActiveSession();
  }

  Future<void> fetchCoordinators() async {
    final list = await _dbHelper.query('koordinator', orderBy: 'nama ASC');
    _koordinators = list.map((m) => Koordinator.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> fetchMembers() async {
    final list = await _dbHelper.query('anggota', orderBy: 'nama ASC');
    _anggotaList = list.map((m) => Anggota.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> fetchSessions() async {
    final list = await _dbHelper.query('sesi_timbang', orderBy: 'tanggal DESC, created_at DESC');
    _sessions = list.map((m) => SesiTimbang.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> checkActiveSession() async {
    final list = await _dbHelper.query('sesi_timbang', where: "status = ?", whereArgs: ['BUKA']);
    if (list.isNotEmpty) {
      _activeSesi = SesiTimbang.fromMap(list.first);
      await fetchActiveSessionData();
    } else {
      _activeSesi = null;
      _activeSessionTransactions = [];
      _activeSessionExpenses = [];
    }
    notifyListeners();
  }

  Future<void> fetchActiveSessionData() async {
    if (_activeSesi == null) return;
    
    // Join transactions with members
    final txList = await _dbHelper.query(
      'transaksi',
      where: "sesi_id = ?",
      whereArgs: [_activeSesi!.sesiId],
      orderBy: 'waktu_input DESC',
    );

    // Hydrate names
    List<Map<String, dynamic>> hydratedTx = [];
    for (var tx in txList) {
      final map = Map<String, dynamic>.from(tx);
      
      // Get member details
      final memberList = await _dbHelper.query('anggota', where: 'anggota_id = ?', whereArgs: [tx['anggota_id']]);
      if (memberList.isNotEmpty) {
        map['anggota_nama'] = memberList.first['nama'];
        map['angkutan'] = memberList.first['tipe_angkutan'];
      }
      
      // Perform calculations
      final calc = KalkulasiService.hitung(
        beratTotal: tx['berat_kg'] as int,
        porsiPersen: 100.0, // base calculation details
        hargaPerKg: _activeSesi!.hargaPerKg,
        tarifAdm: _activeSesi!.tarifAdmPerKg,
        tarifTrsDusun: _activeSesi!.tarifTrsDusun,
        tarifTrsIbol: _activeSesi!.tarifTrsIbol,
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
    _activeSessionTransactions = hydratedTx;

    // Load expenses
    final pglList = await _dbHelper.query(
      'pengeluaran',
      where: "sesi_id = ?",
      whereArgs: [_activeSesi!.sesiId],
      orderBy: 'created_at DESC',
    );
    _activeSessionExpenses = pglList;
    notifyListeners();
  }

  // --- Sesi Operations ---

  Future<bool> bukaSesi({
    required String koordinatorId,
    required String tanggal,
    required int hargaPerKg,
    required int tarifAdm,
    required int tarifTrsDusun,
    required int tarifTrsIbol,
    String? catatan,
  }) async {
    // Check if session date already exists for this coordinator
    final existing = await _dbHelper.query(
      'sesi_timbang',
      where: 'koordinator_id = ? and tanggal = ?',
      whereArgs: [koordinatorId, tanggal],
    );
    if (existing.isNotEmpty) {
      return false;
    }

    final String cleanDate = tanggal.replaceAll('-', '');
    final String koorCode = koordinatorId.replaceAll('KOOR-', '');
    final sesiId = 'SESI$cleanDate$koorCode';

    final sesi = SesiTimbang(
      sesiId: sesiId,
      koordinatorId: koordinatorId,
      tanggal: tanggal,
      hargaPerKg: hargaPerKg,
      tarifAdmPerKg: tarifAdm,
      tarifTrsDusun: tarifTrsDusun,
      tarifTrsIbol: tarifTrsIbol,
      status: 'BUKA',
      catatan: catatan,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _dbHelper.insert('sesi_timbang', sesi.toMap());
    await checkActiveSession();
    return true;
  }

  Future<void> tutupSesi() async {
    if (_activeSesi == null) return;

    final closedSesi = SesiTimbang(
      sesiId: _activeSesi!.sesiId,
      koordinatorId: _activeSesi!.koordinatorId,
      tanggal: _activeSesi!.tanggal,
      hargaPerKg: _activeSesi!.hargaPerKg,
      tarifAdmPerKg: _activeSesi!.tarifAdmPerKg,
      tarifTrsDusun: _activeSesi!.tarifTrsDusun,
      tarifTrsIbol: _activeSesi!.tarifTrsIbol,
      status: 'TUTUP',
      catatan: _activeSesi!.catatan,
      createdAt: _activeSesi!.createdAt,
      closedAt: DateTime.now().toIso8601String(),
    );

    await _dbHelper.insert('sesi_timbang', closedSesi.toMap());
    
    // Perform auto backup on desktop
    await _backupDatabaseFile(_activeSesi!.tanggal, _activeSesi!.sesiId);

    await refreshData();
  }

  Future<void> _backupDatabaseFile(String tanggal, String sesiId) async {
    if (kIsWeb) return;
    try {
      final cleanDate = tanggal.replaceAll('-', '');
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'TPK_Koperasi', 'data.db');
      final backupPath = p.join(dbFolder.path, 'TPK_Koperasi', 'backups', 'TPK_Backup_${cleanDate}_$sesiId.db');
      
      await Directory(p.dirname(backupPath)).create(recursive: true);
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);
        if (kDebugMode) print("Auto backup created: $backupPath");
      }
    } catch (e) {
      if (kDebugMode) print("Auto backup error: $e");
    }
  }

  // --- Transaksi & Timbangan Operations ---

  /// Simpan Weighing Transaction. Handles member loans repayments (FIFO or Manual) and joint ownerships.
  Future<void> simpanTransaksi({
    required String anggotaId1,
    required String? anggotaId2,
    required int beratTotal,
    required double porsi1,
    required double porsi2,
    required int pinjamanDipotong1,
    required int pinjamanDipotong2,
    String? selectedPinjamanId1,
    String? selectedPinjamanId2,
  }) async {
    if (_activeSesi == null) return;

    final timestamp = DateTime.now().toIso8601String();
    final uniqueId = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
    final noStruk = await generateNextNoStruk(_activeSesi!.tanggal);

    // Retrieve default transport type for primary member
    final members = await _dbHelper.query('anggota', where: 'anggota_id = ?', whereArgs: [anggotaId1]);
    final tipeAngkutan = members.isNotEmpty ? members.first['tipe_angkutan'] as String : 'SENDIRI';

    // Insert Base Transaction
    final tx = Transaksi(
      transaksiId: uniqueId,
      sesiId: _activeSesi!.sesiId,
      anggotaId: anggotaId1,
      beratKg: beratTotal,
      pinjamanDipotong: pinjamanDipotong1 + pinjamanDipotong2,
      noStruk: noStruk,
      waktuInput: timestamp,
    );
    await _dbHelper.insert('transaksi', tx.toMap());

    // If joint ownership is active, record ownership splits
    if (anggotaId2 != null && porsi2 > 0) {
      await _dbHelper.insert('kepemilikan_bersama', {
        'transaksi_id': uniqueId,
        'anggota_id': anggotaId1,
        'porsi_persen': porsi1,
        'catatan': members.first['nama'],
      });

      final member2 = await _dbHelper.query('anggota', where: 'anggota_id = ?', whereArgs: [anggotaId2]);
      await _dbHelper.insert('kepemilikan_bersama', {
        'transaksi_id': uniqueId,
        'anggota_id': anggotaId2,
        'porsi_persen': porsi2,
        'catatan': member2.first['nama'],
      });
    }

    // Process Loan Repayments
    if (pinjamanDipotong1 > 0) {
      await _applyLoanRepayment(anggotaId1, pinjamanDipotong1, selectedPinjamanId1);
    }
    if (anggotaId2 != null && pinjamanDipotong2 > 0) {
      await _applyLoanRepayment(anggotaId2, pinjamanDipotong2, selectedPinjamanId2);
    }

    await fetchActiveSessionData();
  }

  Future<void> _applyLoanRepayment(String anggotaId, int amount, String? specificLoanId) async {
    if (specificLoanId != null && specificLoanId != 'FIFO') {
      // Deduct from specific loan
      final loans = await _dbHelper.query('pinjaman', where: 'pinjaman_id = ?', whereArgs: [specificLoanId]);
      if (loans.isNotEmpty) {
        final currentSisa = loans.first['saldo_sisa'] as int;
        final nextSisa = currentSisa - amount;
        await _dbHelper.update(
          'pinjaman',
          {
            'saldo_sisa': nextSisa,
            'status': nextSisa <= 0 ? 'LUNAS' : 'AKTIF',
          },
          where: 'pinjaman_id = ?',
          whereArgs: [specificLoanId],
        );
      }
    } else {
      // FIFO Repayment (deduct oldest active loans first)
      final loans = await _dbHelper.query(
        'pinjaman',
        where: "anggota_id = ? and status = ?",
        whereArgs: [anggotaId, 'AKTIF'],
        orderBy: 'created_at ASC, pinjaman_id ASC',
      );

      int remainingDeduction = amount;
      for (var loan in loans) {
        if (remainingDeduction <= 0) break;

        final loanId = loan['pinjaman_id'] as String;
        final currentSisa = loan['saldo_sisa'] as int;

        if (remainingDeduction >= currentSisa) {
          await _dbHelper.update(
            'pinjaman',
            {'saldo_sisa': 0, 'status': 'LUNAS'},
            where: 'pinjaman_id = ?',
            whereArgs: [loanId],
          );
          remainingDeduction -= currentSisa;
        } else {
          int nextSisa = currentSisa - remainingDeduction;
          await _dbHelper.update(
            'pinjaman',
            {'saldo_sisa': nextSisa},
            where: 'pinjaman_id = ?',
            whereArgs: [loanId],
          );
          remainingDeduction = 0;
        }
      }
    }
  }

  Future<void> voidTransaksi(String transaksiId) async {
    // 1. Fetch transaction details
    final txs = await _dbHelper.query('transaksi', where: 'transaksi_id = ?', whereArgs: [transaksiId]);
    if (txs.isEmpty) return;
    
    final txMap = txs.first;
    final totalDipotong = txMap['pinjaman_dipotong'] as int;
    final anggotaId = txMap['anggota_id'] as String;

    // 2. Set transaction to Void
    await _dbHelper.update('transaksi', {'is_void': 1}, where: 'transaksi_id = ?', whereArgs: [transaksiId]);

    // 3. Refund Loan deductions
    if (totalDipotong > 0) {
      // Find splits if joint ownership
      final splits = await _dbHelper.query('kepemilikan_bersama', where: 'transaksi_id = ?', whereArgs: [transaksiId]);
      if (splits.isNotEmpty) {
        // Splitted refund
        // Since we did FIFO or manual, we refund the amount back to the loans of both members.
        // For simplicity: add refund to the last lunas or active loans of each owner
        for (var split in splits) {
          final splitAnggotaId = split['anggota_id'] as String;
          final splitPct = split['porsi_persen'] as double;
          // Estimate portion of deduction (or just divide)
          // To be precise, we check if they had loans. Refund to their loans.
          final refundVal = (totalDipotong * (splitPct / 100.0)).round();
          await _refundLoanAmount(splitAnggotaId, refundVal);
        }
      } else {
        await _refundLoanAmount(anggotaId, totalDipotong);
      }
    }

    await fetchActiveSessionData();
  }

  Future<void> _refundLoanAmount(String anggotaId, int amount) async {
    // To refund, find loans that have been modified recently, or simply add it back to the oldest active/lunas loan.
    // If no active loan exists, we can reactivate the last LUNAS loan.
    // Find all loans for member sorted DESC by created_at
    final loans = await _dbHelper.query(
      'pinjaman',
      where: 'anggota_id = ?',
      whereArgs: [anggotaId],
      orderBy: 'created_at DESC',
    );

    int remainingRefund = amount;
    for (var loan in loans) {
      if (remainingRefund <= 0) break;
      
      final loanId = loan['pinjaman_id'] as String;
      final pokok = loan['jumlah_pokok'] as int;
      final currentSisa = loan['saldo_sisa'] as int;
      final status = loan['status'] as String;

      int maxRefundable = pokok - currentSisa;
      if (maxRefundable <= 0) continue; // already at max balance

      if (remainingRefund >= maxRefundable) {
        await _dbHelper.update(
          'pinjaman',
          {
            'saldo_sisa': pokok,
            'status': 'AKTIF',
          },
          where: 'pinjaman_id = ?',
          whereArgs: [loanId],
        );
        remainingRefund -= maxRefundable;
      } else {
        await _dbHelper.update(
          'pinjaman',
          {
            'saldo_sisa': currentSisa + remainingRefund,
            'status': 'AKTIF',
          },
          where: 'pinjaman_id = ?',
          whereArgs: [loanId],
        );
        remainingRefund = 0;
      }
    }
  }

  Future<String> generateNextNoStruk(String date) async {
    final cleanDate = date.replaceAll('-', '');
    final result = await _dbHelper.rawQuery(
      "SELECT COUNT(*) as cnt FROM transaksi WHERE no_struk LIKE 'STR-$cleanDate-%'"
    );
    int count = 0;
    if (result.isNotEmpty) {
      count = (result.first['cnt'] as num).toInt();
    }
    final nextNum = count + 1;
    final padNum = nextNum.toString().padLeft(3, '0');
    return 'STR-$cleanDate-$padNum';
  }

  // --- Pinjaman Operations ---

  Future<void> tambahPinjaman(String anggotaId, int jumlahPokok, String? keterangan) async {
    final timestamp = DateTime.now().toIso8601String();
    final pinjamanId = 'PIN-${DateTime.now().millisecondsSinceEpoch}';
    final date = timestamp.split('T')[0];

    final loan = Pinjaman(
      pinjamanId: pinjamanId,
      anggotaId: anggotaId,
      tanggalPinjam: date,
      jumlahPokok: jumlahPokok,
      saldoSisa: jumlahPokok,
      status: 'AKTIF',
      keterangan: keterangan,
      createdAt: timestamp,
    );

    await _dbHelper.insert('pinjaman', loan.toMap());
    await refreshData();
  }

  Future<List<Map<String, dynamic>>> getHistoriPinjaman(String anggotaId) async {
    final list = await _dbHelper.query(
      'pinjaman',
      where: 'anggota_id = ?',
      whereArgs: [anggotaId],
      orderBy: 'created_at DESC',
    );
    return list;
  }

  Future<List<Map<String, dynamic>>> getAllPinjaman() async {
    final list = await _dbHelper.query(
      'pinjaman',
      orderBy: 'created_at DESC',
    );
    
    List<Map<String, dynamic>> hydrated = [];
    for (var loan in list) {
      final map = Map<String, dynamic>.from(loan);
      final member = await _dbHelper.query('anggota', where: 'anggota_id = ?', whereArgs: [loan['anggota_id']]);
      if (member.isNotEmpty) {
        map['anggota_nama'] = member.first['nama'];
      } else {
        map['anggota_nama'] = 'Tidak Diketahui';
      }
      hydrated.add(map);
    }
    return hydrated;
  }

  // --- Anggota Operations ---

  Future<void> tambahAnggota({
    required String nama,
    required String koordinatorId,
    required String tipeAngkutan,
    String? noHp,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final anggotaId = 'ANK-Y${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final member = Anggota(
      anggotaId: anggotaId,
      koordinatorId: koordinatorId,
      nama: nama,
      tipeAngkutan: tipeAngkutan,
      noHp: noHp,
      statusAktif: 1,
      createdAt: timestamp,
    );

    await _dbHelper.insert('anggota', member.toMap());
    await fetchMembers();
  }

  Future<void> editAnggota({
    required String anggotaId,
    required String nama,
    required String tipeAngkutan,
    required int statusAktif,
    String? noHp,
  }) async {
    await _dbHelper.update(
      'anggota',
      {
        'nama': nama,
        'tipe_angkutan': tipeAngkutan,
        'status_aktif': statusAktif,
        'no_hp': noHp,
      },
      where: 'anggota_id = ?',
      whereArgs: [anggotaId],
    );
    await fetchMembers();
  }

  // --- Pengeluaran Operations ---

  Future<void> tambahPengeluaran(String kategori, String? namaPenerima, int jumlah, String? keterangan) async {
    if (_activeSesi == null) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final pglId = 'PGL-${DateTime.now().millisecondsSinceEpoch}';

    final exp = Pengeluaran(
      pengeluaranId: pglId,
      sesiId: _activeSesi!.sesiId,
      kategori: kategori,
      namaPenerima: namaPenerima,
      jumlah: jumlah,
      keterangan: keterangan,
      createdAt: timestamp,
    );

    await _dbHelper.insert('pengeluaran', exp.toMap());
    await fetchActiveSessionData();
  }

  Future<void> hapusPengeluaran(String pengeluaranId) async {
    await _dbHelper.delete('pengeluaran', where: 'pengeluaran_id = ?', whereArgs: [pengeluaranId]);
    await fetchActiveSessionData();
  }

  // --- Global Database Utilities ---
  
  Future<void> clearDatabase() async {
    await _dbHelper.clearAllData();
    await refreshData();
  }
}

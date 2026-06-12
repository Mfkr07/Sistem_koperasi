import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // In-memory tables for Web fallback
  final Map<String, List<Map<String, dynamic>>> _webDb = {
    'koordinator': [],
    'anggota': [],
    'sesi_timbang': [],
    'transaksi': [],
    'pinjaman': [],
    'pengeluaran': [],
    'kepemilikan_bersama': [],
  };

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      // Return a dummy database object or handle web separately
      // On Web, we simulate CRUD operations directly using _webDb
      return _database ??= _MockDatabase() as Database;
    }

    if (_database != null) return _database!;
    _database = await _initDB('data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for Windows desktop
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;

    final dbFolder = await getApplicationDocumentsDirectory();
    final path = p.join(dbFolder.path, 'TPK_Koperasi', filePath);
    
    // Ensure parent directory exists
    await Directory(p.dirname(path)).create(recursive: true);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE koordinator (
        koordinator_id TEXT PRIMARY KEY,
        nama TEXT NOT NULL,
        catatan TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE anggota (
        anggota_id TEXT PRIMARY KEY,
        koordinator_id TEXT NOT NULL,
        nama TEXT NOT NULL,
        tipe_angkutan TEXT NOT NULL,
        no_hp TEXT,
        status_aktif INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (koordinator_id) REFERENCES koordinator (koordinator_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sesi_timbang (
        sesi_id TEXT PRIMARY KEY,
        koordinator_id TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        harga_per_kg INTEGER NOT NULL,
        tarif_adm_per_kg INTEGER NOT NULL,
        tarif_trs_dusun INTEGER NOT NULL,
        tarif_trs_ibol INTEGER NOT NULL,
        status TEXT NOT NULL,
        catatan TEXT,
        created_at TEXT NOT NULL,
        closed_at TEXT,
        FOREIGN KEY (koordinator_id) REFERENCES koordinator (koordinator_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transaksi (
        transaksi_id TEXT PRIMARY KEY,
        sesi_id TEXT NOT NULL,
        anggota_id TEXT NOT NULL,
        berat_kg INTEGER NOT NULL,
        pinjaman_dipotong INTEGER DEFAULT 0,
        no_struk TEXT UNIQUE,
        sudah_cetak INTEGER DEFAULT 0,
        waktu_cetak TEXT,
        waktu_input TEXT NOT NULL,
        is_void INTEGER DEFAULT 0,
        FOREIGN KEY (sesi_id) REFERENCES sesi_timbang (sesi_id),
        FOREIGN KEY (anggota_id) REFERENCES anggota (anggota_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pinjaman (
        pinjaman_id TEXT PRIMARY KEY,
        anggota_id TEXT NOT NULL,
        tanggal_pinjam TEXT NOT NULL,
        jumlah_pokok INTEGER NOT NULL,
        saldo_sisa INTEGER NOT NULL,
        status TEXT NOT NULL,
        keterangan TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (anggota_id) REFERENCES anggota (anggota_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pengeluaran (
        pengeluaran_id TEXT PRIMARY KEY,
        sesi_id TEXT NOT NULL,
        kategori TEXT NOT NULL,
        nama_penerima TEXT,
        jumlah INTEGER NOT NULL,
        keterangan TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (sesi_id) REFERENCES sesi_timbang (sesi_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE kepemilikan_bersama (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaksi_id TEXT NOT NULL,
        anggota_id TEXT NOT NULL,
        porsi_persen REAL NOT NULL,
        catatan TEXT,
        FOREIGN KEY (transaksi_id) REFERENCES transaksi (transaksi_id),
        FOREIGN KEY (anggota_id) REFERENCES anggota (anggota_id)
      )
    ''');
  }

  // Generic DB Methods abstracting Desktop / Web

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    if (kIsWeb) {
      List<Map<String, dynamic>> results = List.from(_webDb[table] ?? []);
      // Apply basic where filtering
      if (where != null && whereArgs != null) {
        results = _applyWebFiltering(results, where, whereArgs);
      }
      // Apply sorting if needed
      if (orderBy != null) {
        results = _applyWebSorting(results, orderBy);
      }
      return results;
    } else {
      final db = await database;
      return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
    }
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    if (kIsWeb) {
      final list = _webDb[table] ??= [];
      // If table has autoincrement ID like kepemilikan_bersama
      Map<String, dynamic> row = Map.from(values);
      if (table == 'kepemilikan_bersama' && !row.containsKey('id')) {
        int nextId = list.length + 1;
        row['id'] = nextId;
      }
      
      // On conflicts, replace
      if (table == 'koordinator' || table == 'anggota' || table == 'sesi_timbang' || table == 'transaksi' || table == 'pinjaman' || table == 'pengeluaran') {
        final keyName = '${table}_id';
        list.removeWhere((item) => item[keyName] == row[keyName]);
      }
      list.add(row);
      return 1;
    } else {
      final db = await database;
      return await db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    if (kIsWeb) {
      final list = _webDb[table] ??= [];
      int count = 0;
      for (int i = 0; i < list.length; i++) {
        bool matches = true;
        if (where != null && whereArgs != null) {
          matches = _matchesWebFilter(list[i], where, whereArgs);
        }
        if (matches) {
          final updatedRow = Map<String, dynamic>.from(list[i])..addAll(values);
          list[i] = updatedRow;
          count++;
        }
      }
      return count;
    } else {
      final db = await database;
      return await db.update(table, values, where: where, whereArgs: whereArgs);
    }
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    if (kIsWeb) {
      final list = _webDb[table] ??= [];
      int originalLength = list.length;
      if (where != null && whereArgs != null) {
        list.removeWhere((item) => _matchesWebFilter(item, where, whereArgs));
      } else {
        list.clear();
      }
      return originalLength - list.length;
    } else {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    }
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    if (kIsWeb) {
      // Simulate common aggregate queries used in our app
      String queryLower = sql.toLowerCase();
      
      if (queryLower.contains('select sum(') || queryLower.contains('count(')) {
        // Handle aggregate calculations for Tutup Sesi & Rekap
        String fromTable = '';
        if (queryLower.contains('from transaksi')) fromTable = 'transaksi';
        if (queryLower.contains('from pengeluaran')) fromTable = 'pengeluaran';
        if (queryLower.contains('from pinjaman')) fromTable = 'pinjaman';
        
        List<Map<String, dynamic>> source = List.from(_webDb[fromTable] ?? []);
        
        // Apply simple where if present
        if (sql.contains('sesi_id = ?')) {
          final sesiId = arguments?[0];
          source = source.where((row) => row['sesi_id'] == sesiId).toList();
        }
        if (sql.contains('is_void = 0')) {
          source = source.where((row) => row['is_void'] == 0).toList();
        }
        if (sql.contains('anggota_id = ?')) {
          final anggotaId = arguments?[0];
          source = source.where((row) => row['anggota_id'] == anggotaId).toList();
        }
        
        if (fromTable == 'transaksi') {
          int totalTonase = 0;
          int totalPinjaman = 0;
          int count = 0;
          for (var r in source) {
            totalTonase += (r['berat_kg'] as num).toInt();
            totalPinjaman += (r['pinjaman_dipotong'] as num).toInt();
            count++;
          }
          return [{
            'total_tonase': totalTonase,
            'total_pinjaman': totalPinjaman,
            'total_transaksi': count,
          }];
        } else if (fromTable == 'pengeluaran') {
          int totalPengeluaran = 0;
          for (var r in source) {
            totalPengeluaran += (r['jumlah'] as num).toInt();
          }
          return [{
            'total_pengeluaran': totalPengeluaran,
          }];
        }
      }
      
      // Fallback for custom queries - just return empty or unfiltered list
      return [];
    } else {
      final db = await database;
      return await db.rawQuery(sql, arguments);
    }
  }

  Future<void> execute(String sql) async {
    if (!kIsWeb) {
      final db = await database;
      await db.execute(sql);
    }
  }

  // Web Helper logic for filtering lists of maps
  List<Map<String, dynamic>> _applyWebFiltering(
    List<Map<String, dynamic>> list,
    String where,
    List<dynamic> whereArgs,
  ) {
    return list.where((item) => _matchesWebFilter(item, where, whereArgs)).toList();
  }

  bool _matchesWebFilter(Map<String, dynamic> item, String where, List<dynamic> whereArgs) {
    // E.g., "koordinator_id = ?" or "status = ?"
    final parts = where.split('and').map((s) => s.trim()).toList();
    int argIndex = 0;
    
    for (var part in parts) {
      if (part.contains('=')) {
        final key = part.split('=')[0].trim();
        final expectedVal = whereArgs[argIndex++];
        if (item[key] != expectedVal) return false;
      } else if (part.contains('is null')) {
        final key = part.split('is null')[0].trim();
        if (item[key] != null) return false;
      }
    }
    return true;
  }

  List<Map<String, dynamic>> _applyWebSorting(List<Map<String, dynamic>> list, String orderBy) {
    final sortParts = orderBy.split(' ');
    final sortKey = sortParts[0].trim();
    bool desc = sortParts.length > 1 && sortParts[1].toLowerCase() == 'desc';
    
    list.sort((a, b) {
      var valA = a[sortKey];
      var valB = b[sortKey];
      if (valA == null || valB == null) return 0;
      int compare = 0;
      if (valA is Comparable && valB is Comparable) {
        compare = valA.compareTo(valB);
      }
      return desc ? -compare : compare;
    });
    return list;
  }
  
  Future<void> closeDatabase() async {
    if (kIsWeb) return;
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Wipe database for testing or restore
  Future<void> clearAllData() async {
    if (kIsWeb) {
      _webDb.forEach((key, value) {
        value.clear();
      });
    } else {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('kepemilikan_bersama');
        await txn.delete('transaksi');
        await txn.delete('pengeluaran');
        await txn.delete('pinjaman');
        await txn.delete('sesi_timbang');
        await txn.delete('anggota');
        await txn.delete('koordinator');
      });
    }
  }
}

// Dummy Database class to satisfy compiler types on Web
class _MockDatabase {}

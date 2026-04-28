// lib/shared/database/database_helper.dart
/// SQLite singleton for crops, farmers, farms, and sync queue persistence.

import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  final Logger _logger = Logger();

  Database? _database;
  Database? _databaseOverride;
  Database? _fallbackDatabase;
  String? _databasePathOverride;

  void setDatabaseForTesting(Database database) {
    _databaseOverride = database;
  }

  void setDatabasePathForTesting(String databasePath) {
    _databasePathOverride = databasePath;
  }

  Future<void> close() async {
    try {
      final Database? overrideDatabase = _databaseOverride;
      if (overrideDatabase != null) {
        await overrideDatabase.close();
        _databaseOverride = null;
      }

      final Database? currentDatabase = _database;
      if (currentDatabase != null) {
        await currentDatabase.close();
        _database = null;
      }

      final Database? fallbackDatabase = _fallbackDatabase;
      if (fallbackDatabase != null) {
        await fallbackDatabase.close();
        _fallbackDatabase = null;
      }
    } catch (error, stackTrace) {
      _logger.e('close failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<Database> get database async {
    try {
      final Database? overrideDatabase = _databaseOverride;
      if (overrideDatabase != null) {
        return overrideDatabase;
      }

      final Database? currentDatabase = _database;
      if (currentDatabase != null) {
        return currentDatabase;
      }

      _database = await _initDatabase();
      return _database!;
    } catch (error, stackTrace) {
      _logger.e('database initialization failed', error: error, stackTrace: stackTrace);

      try {
        final Database? fallbackDatabase = _fallbackDatabase;
        if (fallbackDatabase != null) {
          return fallbackDatabase;
        }

        _fallbackDatabase = await _createFallbackDatabase();
        return _fallbackDatabase!;
      } catch (fallbackError, fallbackStackTrace) {
        _logger.e(
          'fallback database initialization failed',
          error: fallbackError,
          stackTrace: fallbackStackTrace,
        );
        return _NoopDatabase(_logger);
      }
    }
  }

  Future<Database> _initDatabase() async {
    final String dbPath = _databasePathOverride ?? path.join(await getDatabasesPath(), 'agritrade.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<Database> _createFallbackDatabase() async {
    return openDatabase(
      ':memory:',
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      singleInstance: false,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.farmersTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnName} TEXT NOT NULL,
        ${DatabaseConstants.columnPhone} TEXT,
        ${DatabaseConstants.columnEmail} TEXT,
        ${DatabaseConstants.columnBio} TEXT,
        ${DatabaseConstants.columnProfileImageUrl} TEXT,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnSynced} INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.cropsTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnFarmerId} TEXT NOT NULL,
        ${DatabaseConstants.columnName} TEXT NOT NULL,
        ${DatabaseConstants.columnQuantity} REAL NOT NULL,
        ${DatabaseConstants.columnUnit} TEXT NOT NULL,
        ${DatabaseConstants.columnPricePerUnit} REAL NOT NULL,
        ${DatabaseConstants.columnImageUrl} TEXT,
        ${DatabaseConstants.columnLocalImagePath} TEXT,
        ${DatabaseConstants.columnDescription} TEXT,
        ${DatabaseConstants.columnListedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnExpiresAt} INTEGER,
        ${DatabaseConstants.columnStatus} TEXT NOT NULL DEFAULT 'active',
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnSynced} INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.farmsTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnFarmerId} TEXT NOT NULL,
        ${DatabaseConstants.columnName} TEXT NOT NULL,
        ${DatabaseConstants.columnLatitude} REAL,
        ${DatabaseConstants.columnLongitude} REAL,
        ${DatabaseConstants.columnSizeHa} REAL,
        ${DatabaseConstants.columnAddress} TEXT,
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnSynced} INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.syncQueueTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnTableName} TEXT NOT NULL,
        ${DatabaseConstants.columnRecordId} TEXT NOT NULL,
        ${DatabaseConstants.columnOperation} TEXT NOT NULL,
        ${DatabaseConstants.columnPayload} TEXT NOT NULL,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnRetryCount} INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration hooks are intentionally empty until schema version increases.
  }

  Future<void> insertCrop(Map<String, dynamic> data) async {
    try {
      final Database db = await database;
      await db.insert(
        DatabaseConstants.cropsTable,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error, stackTrace) {
      _logger.e('insertCrop failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<List<Map<String, dynamic>>> getCropsByFarmer(String farmerId) async {
    try {
      final Database db = await database;
      return await db.query(
        DatabaseConstants.cropsTable,
        where: '${DatabaseConstants.columnFarmerId} = ?',
        whereArgs: <Object?>[farmerId],
        orderBy: '${DatabaseConstants.columnListedAt} DESC',
      );
    } catch (error, stackTrace) {
      _logger.e('getCropsByFarmer failed', error: error, stackTrace: stackTrace);
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>?> getCropById(String id) async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        DatabaseConstants.cropsTable,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      return rows.first;
    } catch (error, stackTrace) {
      _logger.e('getCropById failed', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> updateCrop(String id, Map<String, dynamic> data) async {
    try {
      final Database db = await database;
      await db.update(
        DatabaseConstants.cropsTable,
        data,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[id],
      );
    } catch (error, stackTrace) {
      _logger.e('updateCrop failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> deleteCrop(String id) async {
    try {
      final Database db = await database;
      await db.delete(
        DatabaseConstants.cropsTable,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[id],
      );
    } catch (error, stackTrace) {
      _logger.e('deleteCrop failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCrops() async {
    try {
      final Database db = await database;
      return await db.query(
        DatabaseConstants.cropsTable,
        where: '${DatabaseConstants.columnSynced} = ?',
        whereArgs: <Object?>[0],
        orderBy: '${DatabaseConstants.columnUpdatedAt} DESC',
      );
    } catch (error, stackTrace) {
      _logger.e('getUnsyncedCrops failed', error: error, stackTrace: stackTrace);
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> markCropSynced(String id) async {
    try {
      final Database db = await database;
      await db.update(
        DatabaseConstants.cropsTable,
        <String, dynamic>{DatabaseConstants.columnSynced: 1},
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[id],
      );
    } catch (error, stackTrace) {
      _logger.e('markCropSynced failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> insertFarmer(Map<String, dynamic> data) async {
    try {
      final Database db = await database;
      await db.insert(
        DatabaseConstants.farmersTable,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error, stackTrace) {
      _logger.e('insertFarmer failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<Map<String, dynamic>?> getFarmerById(String id) async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        DatabaseConstants.farmersTable,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      return rows.first;
    } catch (error, stackTrace) {
      _logger.e('getFarmerById failed', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> updateFarmer(String id, Map<String, dynamic> data) async {
    try {
      final Database db = await database;
      await db.update(
        DatabaseConstants.farmersTable,
        data,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[id],
      );
    } catch (error, stackTrace) {
      _logger.e('updateFarmer failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> markFarmerSynced(String id) async {
    try {
      final Database db = await database;
      await db.update(
        DatabaseConstants.farmersTable,
        <String, dynamic>{DatabaseConstants.columnSynced: 1},
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[id],
      );
    } catch (error, stackTrace) {
      _logger.e('markFarmerSynced failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> insertFarm(Map<String, dynamic> data) async {
    try {
      final Database db = await database;
      await db.insert(
        DatabaseConstants.farmsTable,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error, stackTrace) {
      _logger.e('insertFarm failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<Map<String, dynamic>?> getFarmByUserId(String userId) async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        DatabaseConstants.farmsTable,
        where: '${DatabaseConstants.columnFarmerId} = ?',
        whereArgs: <Object?>[userId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      return rows.first;
    } catch (error, stackTrace) {
      _logger.e('getFarmByUserId failed', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFarmByFarmerId(String farmerId) async {
    return getFarmByUserId(farmerId);
  }

  Future<void> updateFarm(String id, Map<String, dynamic> data) async {
    try {
      final Database db = await database;
      await db.update(
        DatabaseConstants.farmsTable,
        data,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[id],
      );
    } catch (error, stackTrace) {
      _logger.e('updateFarm failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> markFarmSynced(String id) async {
    try {
      final Database db = await database;
      await db.update(
        DatabaseConstants.farmsTable,
        <String, dynamic>{DatabaseConstants.columnSynced: 1},
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[id],
      );
    } catch (error, stackTrace) {
      _logger.e('markFarmSynced failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> addToSyncQueue(
    String tableName,
    String recordId,
    String operation,
    Object payload,
  ) async {
    try {
      final Database db = await database;
      final String payloadText = payload is String ? payload : jsonEncode(payload);
      final Map<String, dynamic> payloadMap = payload is Map<String, dynamic> ? payload : <String, dynamic>{};

      await db.insert(
        DatabaseConstants.syncQueueTable,
        <String, dynamic>{
          DatabaseConstants.columnId: payloadMap[DatabaseConstants.columnId] ?? recordId,
          DatabaseConstants.columnTableName: tableName,
          DatabaseConstants.columnRecordId: recordId,
          DatabaseConstants.columnOperation: operation,
          DatabaseConstants.columnPayload: payloadText,
          DatabaseConstants.columnCreatedAt: payloadMap[DatabaseConstants.columnCreatedAt] ?? DateTime.now().millisecondsSinceEpoch,
          DatabaseConstants.columnRetryCount: 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error, stackTrace) {
      _logger.e('addToSyncQueue failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    try {
      final Database db = await database;
      return await db.query(
        DatabaseConstants.syncQueueTable,
        orderBy: '${DatabaseConstants.columnCreatedAt} ASC',
      );
    } catch (error, stackTrace) {
      _logger.e('getPendingSyncItems failed', error: error, stackTrace: stackTrace);
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> deleteSyncQueueItem(String id) async {
    try {
      final Database db = await database;
      await db.delete(
        DatabaseConstants.syncQueueTable,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[id],
      );
    } catch (error, stackTrace) {
      _logger.e('deleteSyncQueueItem failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> incrementRetryCount(String id) async {
    try {
      final Database db = await database;
      await db.rawUpdate(
        '''
        UPDATE ${DatabaseConstants.syncQueueTable}
        SET ${DatabaseConstants.columnRetryCount} = ${DatabaseConstants.columnRetryCount} + 1
        WHERE ${DatabaseConstants.columnId} = ?
        ''',
        <Object?>[id],
      );
    } catch (error, stackTrace) {
      _logger.e('incrementRetryCount failed', error: error, stackTrace: stackTrace);
    }
  }
}

class _NoopDatabase implements Database {
  _NoopDatabase(this._logger);

  final Logger _logger;
  bool _isOpen = true;

  @override
  String get path => ':noop:';

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    return action(_NoopTransaction(_logger));
  }

  @override
  Future<T> readTransaction<T>(Future<T> Function(Transaction txn) action) async {
    return action(_NoopTransaction(_logger));
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {}

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async => 0;

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async => <Map<String, Object?>>[];

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async => <Map<String, Object?>>[];

  @override
  Future<QueryCursor> rawQueryCursor(
    String sql,
    List<Object?>? arguments, {
    int? bufferSize,
  }) {
    throw UnimplementedError('Noop database does not support cursors.');
  }

  @override
  Future<QueryCursor> queryCursor(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    int? bufferSize,
  }) {
    throw UnimplementedError('Noop database does not support cursors.');
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async => 0;

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async => 0;

  @override
  Batch batch() {
    throw UnimplementedError('Noop database does not support batch operations.');
  }

  @override
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]) async {
    throw UnimplementedError('Noop database does not support devInvokeMethod.');
  }

  @override
  Future<T> devInvokeSqlMethod<T>(String method, String sql, [List<Object?>? arguments]) async {
    throw UnimplementedError('Noop database does not support devInvokeSqlMethod.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopTransaction extends _NoopDatabase implements Transaction {
  _NoopTransaction(super.logger);
}
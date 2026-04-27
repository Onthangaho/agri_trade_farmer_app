// lib/shared/database/database_helper.dart
/// SQLite singleton for crops, farmers, farms, and sync queue persistence.

import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  Database? _database;
  String? _databasePathOverride;

  void setDatabasePathForTesting(String databasePath) {
    _databasePathOverride = databasePath;
  }

  Future<void> close() async {
    final Database? currentDatabase = _database;
    if (currentDatabase != null) {
      await currentDatabase.close();
      _database = null;
    }
  }

  Future<Database> get database async {
    final Database? currentDatabase = _database;
    if (currentDatabase != null) {
      return currentDatabase;
    }
    _database = await _initDatabase();
    return _database!;
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

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.farmersTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnName} TEXT NOT NULL,
        ${DatabaseConstants.columnPhone} TEXT,
        ${DatabaseConstants.columnEmail} TEXT,
        ${DatabaseConstants.columnBio} TEXT,
        ${DatabaseConstants.columnProfileImageUrl} TEXT,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnSynced} INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.cropsTable} (
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
        ${DatabaseConstants.columnStatus} TEXT DEFAULT 'active',
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnSynced} INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.farmsTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnFarmerId} TEXT NOT NULL,
        ${DatabaseConstants.columnName} TEXT NOT NULL,
        ${DatabaseConstants.columnLatitude} REAL,
        ${DatabaseConstants.columnLongitude} REAL,
        ${DatabaseConstants.columnSizeHa} REAL,
        ${DatabaseConstants.columnAddress} TEXT,
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnSynced} INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.syncQueueTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnTableName} TEXT NOT NULL,
        ${DatabaseConstants.columnRecordId} TEXT NOT NULL,
        ${DatabaseConstants.columnOperation} TEXT NOT NULL,
        ${DatabaseConstants.columnPayload} TEXT NOT NULL,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnRetryCount} INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // TODO: Add migration scripts when the schema version increases.
  }

  Future<void> insertCrop(Map<String, dynamic> data) async {
    final Database db = await database;
    await db.insert(DatabaseConstants.cropsTable, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCropsByFarmer(String farmerId) async {
    final Database db = await database;
    return db.query(
      DatabaseConstants.cropsTable,
      where: '${DatabaseConstants.columnFarmerId} = ?',
      whereArgs: <Object?>[farmerId],
      orderBy: '${DatabaseConstants.columnListedAt} DESC',
    );
  }

  Future<Map<String, dynamic>?> getCropById(String id) async {
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
  }

  Future<void> updateCrop(String id, Map<String, dynamic> data) async {
    final Database db = await database;
    await db.update(
      DatabaseConstants.cropsTable,
      data,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteCrop(String id) async {
    final Database db = await database;
    await db.delete(
      DatabaseConstants.cropsTable,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCrops() async {
    final Database db = await database;
    return db.query(
      DatabaseConstants.cropsTable,
      where: '${DatabaseConstants.columnSynced} = ?',
      whereArgs: <Object?>[0],
      orderBy: '${DatabaseConstants.columnUpdatedAt} DESC',
    );
  }

  Future<void> markCropSynced(String id) async {
    final Database db = await database;
    await db.update(
      DatabaseConstants.cropsTable,
      <String, dynamic>{DatabaseConstants.columnSynced: 1},
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> insertFarmer(Map<String, dynamic> data) async {
    final Database db = await database;
    await db.insert(DatabaseConstants.farmersTable, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getFarmerById(String id) async {
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
  }

  Future<void> updateFarmer(String id, Map<String, dynamic> data) async {
    final Database db = await database;
    await db.update(
      DatabaseConstants.farmersTable,
      data,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> markFarmerSynced(String id) async {
    final Database db = await database;
    await db.update(
      DatabaseConstants.farmersTable,
      <String, dynamic>{DatabaseConstants.columnSynced: 1},
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> insertFarm(Map<String, dynamic> data) async {
    final Database db = await database;
    await db.insert(DatabaseConstants.farmsTable, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getFarmByFarmerId(String farmerId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      DatabaseConstants.farmsTable,
      where: '${DatabaseConstants.columnFarmerId} = ?',
      whereArgs: <Object?>[farmerId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<void> updateFarm(String id, Map<String, dynamic> data) async {
    final Database db = await database;
    await db.update(
      DatabaseConstants.farmsTable,
      data,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> markFarmSynced(String id) async {
    final Database db = await database;
    await db.update(
      DatabaseConstants.farmsTable,
      <String, dynamic>{DatabaseConstants.columnSynced: 1},
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> addToSyncQueue(
    String tableName,
    String recordId,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    final Database db = await database;
    await db.insert(
      DatabaseConstants.syncQueueTable,
      <String, dynamic>{
        DatabaseConstants.columnId: payload[DatabaseConstants.columnId] ?? recordId,
        DatabaseConstants.columnTableName: tableName,
        DatabaseConstants.columnRecordId: recordId,
        DatabaseConstants.columnOperation: operation,
        DatabaseConstants.columnPayload: jsonEncode(payload),
        DatabaseConstants.columnCreatedAt: payload[DatabaseConstants.columnCreatedAt] ?? DateTime.now().millisecondsSinceEpoch,
        DatabaseConstants.columnRetryCount: 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final Database db = await database;
    return db.query(
      DatabaseConstants.syncQueueTable,
      orderBy: '${DatabaseConstants.columnCreatedAt} ASC',
    );
  }

  Future<void> deleteSyncQueueItem(String id) async {
    final Database db = await database;
    await db.delete(
      DatabaseConstants.syncQueueTable,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> incrementRetryCount(String id) async {
    final Database db = await database;
    await db.rawUpdate(
      '''
      UPDATE ${DatabaseConstants.syncQueueTable}
      SET ${DatabaseConstants.columnRetryCount} = ${DatabaseConstants.columnRetryCount} + 1
      WHERE ${DatabaseConstants.columnId} = ?
      ''',
      <Object?>[id],
    );
  }
}

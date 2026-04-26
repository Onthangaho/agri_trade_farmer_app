// lib/shared/database/database_helper.dart
/// SQLite helper with schema creation and CRUD support for offline-first data.

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}${Platform.pathSeparator}${DatabaseConstants.databaseName}';
    return openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

  Future<int> insertCrop(Map<String, Object?> values) async {
    final Database db = await database;
    return db.insert(DatabaseConstants.cropsTable, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCrop(String id, Map<String, Object?> values) async {
    final Database db = await database;
    return db.update(
      DatabaseConstants.cropsTable,
      values,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> deleteCrop(String id) async {
    final Database db = await database;
    return db.delete(
      DatabaseConstants.cropsTable,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<Map<String, Object?>>> getCrops({String? farmerId}) async {
    final Database db = await database;
    return db.query(
      DatabaseConstants.cropsTable,
      where: farmerId == null ? null : '${DatabaseConstants.columnFarmerId} = ?',
      whereArgs: farmerId == null ? null : <Object?>[farmerId],
      orderBy: '${DatabaseConstants.columnListedAt} DESC',
    );
  }

  Future<int> insertFarmer(Map<String, Object?> values) async {
    final Database db = await database;
    return db.insert(DatabaseConstants.farmersTable, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateFarmer(String id, Map<String, Object?> values) async {
    final Database db = await database;
    return db.update(
      DatabaseConstants.farmersTable,
      values,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> deleteFarmer(String id) async {
    final Database db = await database;
    return db.delete(
      DatabaseConstants.farmersTable,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<Map<String, Object?>>> getFarmers() async {
    final Database db = await database;
    return db.query(DatabaseConstants.farmersTable, orderBy: '${DatabaseConstants.columnCreatedAt} DESC');
  }

  Future<int> insertFarm(Map<String, Object?> values) async {
    final Database db = await database;
    return db.insert(DatabaseConstants.farmsTable, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateFarm(String id, Map<String, Object?> values) async {
    final Database db = await database;
    return db.update(
      DatabaseConstants.farmsTable,
      values,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> deleteFarm(String id) async {
    final Database db = await database;
    return db.delete(
      DatabaseConstants.farmsTable,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<Map<String, Object?>>> getFarms({String? farmerId}) async {
    final Database db = await database;
    return db.query(
      DatabaseConstants.farmsTable,
      where: farmerId == null ? null : '${DatabaseConstants.columnFarmerId} = ?',
      whereArgs: farmerId == null ? null : <Object?>[farmerId],
      orderBy: '${DatabaseConstants.columnUpdatedAt} DESC',
    );
  }

  Future<int> addToSyncQueue(Map<String, Object?> values) async {
    final Database db = await database;
    return db.insert(DatabaseConstants.syncQueueTable, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> getPendingSyncItems() async {
    final Database db = await database;
    return db.query(
      DatabaseConstants.syncQueueTable,
      orderBy: '${DatabaseConstants.columnCreatedAt} ASC',
    );
  }

  Future<int> deleteSyncQueueItem(String id) async {
    final Database db = await database;
    return db.delete(
      DatabaseConstants.syncQueueTable,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> incrementRetryCount(String id) async {
    final Database db = await database;
    return db.rawUpdate(
      '''
      UPDATE ${DatabaseConstants.syncQueueTable}
      SET ${DatabaseConstants.columnRetryCount} = ${DatabaseConstants.columnRetryCount} + 1
      WHERE ${DatabaseConstants.columnId} = ?
      ''',
      <Object?>[id],
    );
  }
}

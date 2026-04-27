// lib/core/services/sync_service.dart
/// Coordinates queued sync work between local storage and cloud services.

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../features/auth/data/models/farmer_model.dart';
import '../../features/crops/data/models/crop_model.dart';
import '../../features/farms/domain/entities/farm_entity.dart';
import '../../shared/database/database_constants.dart';
import '../../shared/database/database_helper.dart';
import 'connectivity_service.dart';
import 'storage_service.dart';

class SyncService {
  SyncService({
    required DatabaseHelper databaseHelper,
    required ConnectivityService connectivityService,
    required StorageService storageService,
    FirebaseFirestore? firestore,
    Logger? logger,
  })  : _databaseHelper = databaseHelper,
        _connectivityService = connectivityService,
        _storageService = storageService,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();

  final DatabaseHelper _databaseHelper;
  final ConnectivityService _connectivityService;
  final StorageService _storageService;
  final FirebaseFirestore _firestore;
  final Logger _logger;
  bool _isSyncing = false;

  DatabaseHelper get databaseHelper => _databaseHelper;
  ConnectivityService get connectivityService => _connectivityService;
  StorageService get storageService => _storageService;

  Future<SyncResult> syncAllPending() async {
    if (!await _connectivityService.isOnline()) {
      return SyncResult.empty();
    }

    if (_isSyncing) {
      return SyncResult.empty();
    }

    _isSyncing = true;
    final _SyncCounters counters = _SyncCounters();

    try {
      await _syncCrops(counters);
      await _syncFarmer(counters);
      await _syncFarms(counters);
      await _syncQueuedOperations(counters);
      return counters.toResult();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncCrops() async {
    if (!await _connectivityService.isOnline()) {
      return;
    }

    final _SyncCounters counters = _SyncCounters();
    await _syncCrops(counters);
  }

  Future<void> syncFarms() async {
    if (!await _connectivityService.isOnline()) {
      return;
    }

    final _SyncCounters counters = _SyncCounters();
    await _syncFarms(counters);
  }

  Future<void> syncFarmer() async {
    if (!await _connectivityService.isOnline()) {
      return;
    }

    final _SyncCounters counters = _SyncCounters();
    await _syncFarmer(counters);
  }

  Future<int> getPendingCount() async {
    final dynamic db = await _databaseHelper.database;
    final List<Map<String, dynamic>> queueItems = await db.query(DatabaseConstants.syncQueueTable);
    return queueItems.length;
  }

  Future<void> _syncCrops(_SyncCounters counters) async {
    final dynamic db = await _databaseHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DatabaseConstants.cropsTable,
      where: '${DatabaseConstants.columnSynced} = ?',
      whereArgs: <Object?>[0],
      orderBy: '${DatabaseConstants.columnUpdatedAt} ASC',
    );

    for (final Map<String, dynamic> row in rows) {
      final String cropId = row[DatabaseConstants.columnId] as String;
      if (await _shouldSkipRecord(cropId, DatabaseConstants.cropsTable)) {
        counters.skipped += 1;
        continue;
      }

      try {
        final CropModel crop = CropModel.fromJson(row);
        String? imageUrl = crop.imageUrl;

        if (crop.localImagePath != null && crop.localImagePath!.isNotEmpty) {
          final CropImageUploadTask uploadTask = _storageService.uploadCropImage(
            crop.id,
            File(crop.localImagePath!),
          );
          imageUrl = await uploadTask.downloadUrl;
          final CropModel uploadedCrop = crop.copyWith(
            imageUrl: imageUrl,
            localImagePath: null,
            synced: false,
          );
          await _databaseHelper.updateCrop(
            crop.id,
            uploadedCrop.toJson(updatedAtMillis: DateTime.now().millisecondsSinceEpoch),
          );
        }

        final CropModel syncedCrop = crop.copyWith(
          imageUrl: imageUrl,
          localImagePath: null,
          synced: true,
        );

        await _firestore.collection('crops').doc(crop.id).set(
              syncedCrop.toFirestore(),
              SetOptions(merge: true),
            );
        await _databaseHelper.updateCrop(
          crop.id,
          syncedCrop.toJson(updatedAtMillis: DateTime.now().millisecondsSinceEpoch),
        );
        await _databaseHelper.markCropSynced(crop.id);
        await _deleteQueueEntries(DatabaseConstants.cropsTable, crop.id);
        counters.synced += 1;
      } catch (error, stackTrace) {
        _logger.e('syncCrops failed for $cropId', error: error, stackTrace: stackTrace);
        await _incrementRetryForRecord(DatabaseConstants.cropsTable, cropId);
        counters.failed += 1;
      }
    }
  }

  Future<void> _syncFarmer(_SyncCounters counters) async {
    final dynamic db = await _databaseHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DatabaseConstants.farmersTable,
      where: '${DatabaseConstants.columnSynced} = ?',
      whereArgs: <Object?>[0],
      orderBy: '${DatabaseConstants.columnUpdatedAt} ASC',
    );

    for (final Map<String, dynamic> row in rows) {
      final String farmerId = row[DatabaseConstants.columnId] as String;
      if (await _shouldSkipRecord(farmerId, DatabaseConstants.farmersTable)) {
        counters.skipped += 1;
        continue;
      }

      try {
        final FarmerModel farmer = FarmerModel.fromJson(row);
        await _firestore.collection('farmers').doc(farmer.id).set(
              farmer.toFirestore(),
              SetOptions(merge: true),
            );
        await _databaseHelper.insertFarmer(
          farmer.copyWith(synced: true).toJson(updatedAtMillis: DateTime.now().millisecondsSinceEpoch),
        );
        await _databaseHelper.markFarmerSynced(farmer.id);
        await _deleteQueueEntries(DatabaseConstants.farmersTable, farmer.id);
        counters.synced += 1;
      } catch (error, stackTrace) {
        _logger.e('syncFarmer failed for $farmerId', error: error, stackTrace: stackTrace);
        await _incrementRetryForRecord(DatabaseConstants.farmersTable, farmerId);
        counters.failed += 1;
      }
    }
  }

  Future<void> _syncFarms(_SyncCounters counters) async {
    final dynamic db = await _databaseHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DatabaseConstants.farmsTable,
      where: '${DatabaseConstants.columnSynced} = ?',
      whereArgs: <Object?>[0],
      orderBy: '${DatabaseConstants.columnUpdatedAt} ASC',
    );

    for (final Map<String, dynamic> row in rows) {
      final String farmId = row[DatabaseConstants.columnId] as String;
      if (await _shouldSkipRecord(farmId, DatabaseConstants.farmsTable)) {
        counters.skipped += 1;
        continue;
      }

      try {
        final FarmEntity farm = _farmFromRow(row);
        await _firestore.collection('farms').doc(farm.id).set(
              _farmToFirestoreMap(farm),
              SetOptions(merge: true),
            );
        await _databaseHelper.updateFarm(
          farm.id,
          _farmToDbMap(farm, synced: true),
        );
        await _databaseHelper.markFarmSynced(farm.id);
        await _deleteQueueEntries(DatabaseConstants.farmsTable, farm.id);
        counters.synced += 1;
      } catch (error, stackTrace) {
        _logger.e('syncFarms failed for $farmId', error: error, stackTrace: stackTrace);
        await _incrementRetryForRecord(DatabaseConstants.farmsTable, farmId);
        counters.failed += 1;
      }
    }
  }

  Future<void> _syncQueuedOperations(_SyncCounters counters) async {
    final dynamic db = await _databaseHelper.database;
    final List<Map<String, dynamic>> queueItems = await db.query(
      DatabaseConstants.syncQueueTable,
      orderBy: '${DatabaseConstants.columnCreatedAt} ASC',
    );

    for (final Map<String, dynamic> item in queueItems) {
      final String tableName = item[DatabaseConstants.columnTableName] as String;
      final String recordId = item[DatabaseConstants.columnRecordId] as String;
      final String operation = item[DatabaseConstants.columnOperation] as String;

      if (_shouldSkipQueueItem(item)) {
        counters.skipped += 1;
        continue;
      }

      if (tableName == DatabaseConstants.farmersTable && operation == 'update_profile_image') {
        try {
          await _syncFarmerProfileImage(recordId, item);
          await _deleteQueueEntries(tableName, recordId);
          counters.synced += 1;
        } catch (error, stackTrace) {
          _logger.e('syncFarmerProfileImage failed for $recordId', error: error, stackTrace: stackTrace);
          await _incrementRetryForQueueItem(item);
          counters.failed += 1;
        }
        continue;
      }

      if (operation == 'delete') {
        try {
          await _deleteRemoteRecord(tableName, recordId);
          await _deleteQueueEntries(tableName, recordId);
          counters.synced += 1;
        } catch (error, stackTrace) {
          _logger.e('delete queue sync failed for $recordId', error: error, stackTrace: stackTrace);
          await _incrementRetryForQueueItem(item);
          counters.failed += 1;
        }
        continue;
      }

      if (await _isRecordSynced(tableName, recordId)) {
        await _deleteQueueEntries(tableName, recordId);
      }
    }
  }

  Future<void> _syncFarmerProfileImage(String farmerId, Map<String, dynamic> item) async {
    final dynamic payload = jsonDecode(item[DatabaseConstants.columnPayload] as String) as Map<String, dynamic>;
    final String? remoteImageUrl = payload['remoteImageUrl'] as String?;
    final String? localImagePath = payload['localImagePath'] as String?;

    String imageUrl = remoteImageUrl ?? '';
    if (imageUrl.isEmpty && localImagePath != null && localImagePath.isNotEmpty) {
      imageUrl = await _storageService.uploadProfileImage(farmerId, File(localImagePath));
    }

    if (imageUrl.isEmpty) {
      throw StateError('No profile image URL available for farmer $farmerId');
    }

    await _firestore.collection('farmers').doc(farmerId).set(
      <String, dynamic>{'profileImageUrl': imageUrl},
      SetOptions(merge: true),
    );

    final dynamic db = await _databaseHelper.database;
    final Map<String, dynamic>? local = await _databaseHelper.getFarmerById(farmerId);
    if (local != null) {
      await db.update(
        DatabaseConstants.farmersTable,
        <String, dynamic>{
          DatabaseConstants.columnProfileImageUrl: imageUrl,
          DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
          DatabaseConstants.columnSynced: 1,
        },
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[farmerId],
      );
    }

    await _databaseHelper.markFarmerSynced(farmerId);
  }

  Future<void> _deleteRemoteRecord(String tableName, String recordId) async {
    await _firestore.collection(tableName).doc(recordId).delete();
  }

  bool _shouldSkipQueueItem(Map<String, dynamic> item) {
    final int retryCount = (item[DatabaseConstants.columnRetryCount] as num?)?.toInt() ?? 0;
    return retryCount >= 5;
  }

  Future<bool> _shouldSkipRecord(String recordId, String tableName) async {
    final dynamic db = await _databaseHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DatabaseConstants.syncQueueTable,
      where: '${DatabaseConstants.columnTableName} = ? AND ${DatabaseConstants.columnRecordId} = ?',
      whereArgs: <Object?>[tableName, recordId],
    );

    if (rows.isEmpty) {
      return false;
    }

    final int maxRetry = rows
        .map((Map<String, dynamic> row) => (row[DatabaseConstants.columnRetryCount] as num?)?.toInt() ?? 0)
        .reduce((int value, int next) => value > next ? value : next);
    return maxRetry >= 5;
  }

  Future<bool> _isRecordSynced(String tableName, String recordId) async {
    final dynamic db = await _databaseHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      tableName,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: <Object?>[recordId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return false;
    }
    return ((rows.first[DatabaseConstants.columnSynced] as num?) ?? 0).toInt() == 1;
  }

  Future<void> _deleteQueueEntries(String tableName, String recordId) async {
    final dynamic db = await _databaseHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DatabaseConstants.syncQueueTable,
      where: '${DatabaseConstants.columnTableName} = ? AND ${DatabaseConstants.columnRecordId} = ?',
      whereArgs: <Object?>[tableName, recordId],
    );

    for (final Map<String, dynamic> row in rows) {
      await db.delete(
        DatabaseConstants.syncQueueTable,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: <Object?>[row[DatabaseConstants.columnId]],
      );
    }
  }

  Future<void> _incrementRetryForRecord(String tableName, String recordId) async {
    final dynamic db = await _databaseHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DatabaseConstants.syncQueueTable,
      where: '${DatabaseConstants.columnTableName} = ? AND ${DatabaseConstants.columnRecordId} = ?',
      whereArgs: <Object?>[tableName, recordId],
    );

    for (final Map<String, dynamic> row in rows) {
      await db.rawUpdate(
        '''
        UPDATE ${DatabaseConstants.syncQueueTable}
        SET ${DatabaseConstants.columnRetryCount} = ${DatabaseConstants.columnRetryCount} + 1
        WHERE ${DatabaseConstants.columnId} = ?
        ''',
        <Object?>[row[DatabaseConstants.columnId]],
      );
    }
  }

  Future<void> _incrementRetryForQueueItem(Map<String, dynamic> item) async {
    final dynamic db = await _databaseHelper.database;
    await db.rawUpdate(
      '''
      UPDATE ${DatabaseConstants.syncQueueTable}
      SET ${DatabaseConstants.columnRetryCount} = ${DatabaseConstants.columnRetryCount} + 1
      WHERE ${DatabaseConstants.columnId} = ?
      ''',
      <Object?>[item[DatabaseConstants.columnId]],
    );
  }

  FarmEntity _farmFromRow(Map<String, dynamic> row) {
    return FarmEntity(
      id: row[DatabaseConstants.columnId] as String,
      farmerId: row[DatabaseConstants.columnFarmerId] as String,
      name: row[DatabaseConstants.columnName] as String,
      latitude: (row[DatabaseConstants.columnLatitude] as num?)?.toDouble(),
      longitude: (row[DatabaseConstants.columnLongitude] as num?)?.toDouble(),
      sizeHa: (row[DatabaseConstants.columnSizeHa] as num?)?.toDouble(),
      address: row[DatabaseConstants.columnAddress] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row[DatabaseConstants.columnUpdatedAt] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> _farmToFirestoreMap(FarmEntity farm) {
    return <String, dynamic>{
      'farmerId': farm.farmerId,
      'name': farm.name,
      'latitude': farm.latitude,
      'longitude': farm.longitude,
      'sizeHa': farm.sizeHa,
      'address': farm.address,
      'updatedAt': Timestamp.fromDate(farm.updatedAt),
    };
  }

  Map<String, dynamic> _farmToDbMap(FarmEntity farm, {required bool synced}) {
    return <String, dynamic>{
      DatabaseConstants.columnId: farm.id,
      DatabaseConstants.columnFarmerId: farm.farmerId,
      DatabaseConstants.columnName: farm.name,
      DatabaseConstants.columnLatitude: farm.latitude,
      DatabaseConstants.columnLongitude: farm.longitude,
      DatabaseConstants.columnSizeHa: farm.sizeHa,
      DatabaseConstants.columnAddress: farm.address,
      DatabaseConstants.columnUpdatedAt: farm.updatedAt.millisecondsSinceEpoch,
      DatabaseConstants.columnSynced: synced ? 1 : 0,
    };
  }
}

class SyncResult {
  const SyncResult({
    required this.synced,
    required this.failed,
    required this.skipped,
    required this.syncedAt,
  });

  final int synced;
  final int failed;
  final int skipped;
  final DateTime syncedAt;

  factory SyncResult.empty() {
    return SyncResult(
      synced: 0,
      failed: 0,
      skipped: 0,
      syncedAt: DateTime.now(),
    );
  }
}

class _SyncCounters {
  int synced = 0;
  int failed = 0;
  int skipped = 0;

  SyncResult toResult() {
    return SyncResult(
      synced: synced,
      failed: failed,
      skipped: skipped,
      syncedAt: DateTime.now(),
    );
  }
}

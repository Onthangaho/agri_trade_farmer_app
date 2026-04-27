// lib/features/crops/data/repositories/crop_repository_impl.dart
/// Offline-first crop repository combining SQLite local cache and Firestore sync.

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../shared/database/database_constants.dart';
import '../../../../shared/database/database_helper.dart';
import '../../domain/entities/crop_entity.dart';
import '../../domain/repositories/crop_repository.dart';
import '../datasources/firestore_crop_datasource.dart';
import '../datasources/sqlite_crop_datasource.dart';
import '../models/crop_model.dart';

class CropRepositoryImpl implements CropRepository {
  CropRepositoryImpl({
    required SqliteCropDataSource sqliteDataSource,
    required FirestoreCropDataSource firestoreDataSource,
    required DatabaseHelper databaseHelper,
    required StorageService storageService,
    Connectivity? connectivity,
    Logger? logger,
  })  : _sqliteDataSource = sqliteDataSource,
        _firestoreDataSource = firestoreDataSource,
        _databaseHelper = databaseHelper,
        _storageService = storageService,
        _connectivity = connectivity ?? Connectivity(),
        _logger = logger ?? Logger();

  final SqliteCropDataSource _sqliteDataSource;
  final FirestoreCropDataSource _firestoreDataSource;
  final DatabaseHelper _databaseHelper;
  final StorageService _storageService;
  final Connectivity _connectivity;
  final Logger _logger;

  @override
  Future<void> saveCrop(CropEntity crop, {File? imageFile}) async {
    final bool online = await _isOnline();
    String? imageUrl = crop.imageUrl;
    String? localImagePath = crop.localImagePath;

    if (imageFile != null && (crop.imageUrl == null || crop.imageUrl!.isEmpty)) {
      if (online) {
        try {
          final CropImageUploadTask uploadTask = _storageService.uploadCropImage(crop.id, imageFile);
          imageUrl = await uploadTask.downloadUrl;
          localImagePath = null;
        } on StorageServiceException catch (error, stackTrace) {
          _logger.e('saveCrop image upload failed', error: error, stackTrace: stackTrace);
          localImagePath = imageFile.path;
          await _enqueueImageUpload(crop.id, imageFile.path);
        } catch (error, stackTrace) {
          _logger.e('saveCrop image upload unexpected failure', error: error, stackTrace: stackTrace);
          localImagePath = imageFile.path;
          await _enqueueImageUpload(crop.id, imageFile.path);
        }
      } else {
        localImagePath = imageFile.path;
        await _enqueueImageUpload(crop.id, imageFile.path);
      }
    }

    final CropEntity cropWithImage = crop.copyWith(
      imageUrl: imageUrl,
      localImagePath: localImagePath,
    );
    final CropModel localModel = CropModel.fromEntity(cropWithImage, synced: false);
    await _sqliteDataSource.saveCrop(localModel);

    if (!online) {
      await _enqueueCropSync(localModel.id, 'insert', localModel.toFirestore());
      return;
    }

    try {
      await _firestoreDataSource.saveCrop(localModel);
      await _sqliteDataSource.markCropSynced(localModel.id);
    } on FirebaseException catch (error, stackTrace) {
      _logger.e('saveCrop cloud sync failed', error: error, stackTrace: stackTrace);
      await _enqueueCropSync(localModel.id, 'insert', localModel.toFirestore());
    } catch (error, stackTrace) {
      _logger.e('saveCrop unexpected cloud sync failure', error: error, stackTrace: stackTrace);
      await _enqueueCropSync(localModel.id, 'insert', localModel.toFirestore());
    }
  }

  @override
  Future<List<CropEntity>> getCrops(String farmerId) async {
    final List<CropModel> local = await _sqliteDataSource.getCropsByFarmer(farmerId);

    final bool online = await _isOnline();
    if (online) {
      unawaited(_refreshFromCloud(farmerId));
    }

    return local;
  }

  @override
  Future<CropEntity?> getCropById(String id) {
    return _sqliteDataSource.getCropById(id);
  }

  @override
  Future<void> updateCrop(CropEntity crop) async {
    final CropModel localModel = CropModel.fromEntity(crop, synced: false);
    await _sqliteDataSource.updateCrop(localModel);

    final bool online = await _isOnline();
    if (!online) {
      await _enqueueCropSync(localModel.id, 'update', localModel.toFirestore());
      return;
    }

    try {
      await _firestoreDataSource.saveCrop(localModel);
      await _sqliteDataSource.markCropSynced(localModel.id);
    } on FirebaseException catch (error, stackTrace) {
      _logger.e('updateCrop cloud sync failed', error: error, stackTrace: stackTrace);
      await _enqueueCropSync(localModel.id, 'update', localModel.toFirestore());
    } catch (error, stackTrace) {
      _logger.e('updateCrop unexpected cloud sync failure', error: error, stackTrace: stackTrace);
      await _enqueueCropSync(localModel.id, 'update', localModel.toFirestore());
    }
  }

  @override
  Future<void> deleteCrop(String id) async {
    await _sqliteDataSource.deleteCrop(id);

    final bool online = await _isOnline();
    if (!online) {
      await _enqueueCropSync(id, 'delete', <String, dynamic>{'id': id});
      return;
    }

    try {
      await _firestoreDataSource.deleteCrop(id);
    } on FirebaseException catch (error, stackTrace) {
      _logger.e('deleteCrop cloud delete failed', error: error, stackTrace: stackTrace);
      await _enqueueCropSync(id, 'delete', <String, dynamic>{'id': id});
    } catch (error, stackTrace) {
      _logger.e('deleteCrop unexpected cloud delete failure', error: error, stackTrace: stackTrace);
      await _enqueueCropSync(id, 'delete', <String, dynamic>{'id': id});
    }
  }

  @override
  Future<void> syncPendingCrops() async {
    final bool online = await _isOnline();
    if (!online) {
      return;
    }

    final List<CropModel> unsynced = await _sqliteDataSource.getUnsyncedCrops();
    for (final CropModel crop in unsynced) {
      try {
        await _firestoreDataSource.saveCrop(crop.copyWith(synced: true));
        await _sqliteDataSource.markCropSynced(crop.id);
      } on FirebaseException catch (error, stackTrace) {
        _logger.e('syncPendingCrops failed for ${crop.id}', error: error, stackTrace: stackTrace);
        await _databaseHelper.incrementRetryCount(crop.id);
      } catch (error, stackTrace) {
        _logger.e('syncPendingCrops unexpected failure for ${crop.id}', error: error, stackTrace: stackTrace);
        await _databaseHelper.incrementRetryCount(crop.id);
      }
    }
  }

  Future<void> _refreshFromCloud(String farmerId) async {
    try {
      final List<CropModel> remote = await _firestoreDataSource.getCrops(farmerId);
      for (final CropModel crop in remote) {
        final CropModel? localCrop = await _sqliteDataSource.getCropById(crop.id);

        // Keep local pending edits; they must be synced, not overwritten by stale cloud copies.
        if (localCrop != null && !localCrop.synced) {
          continue;
        }

        await _sqliteDataSource.saveCrop(crop.copyWith(synced: true));
      }
    } catch (error, stackTrace) {
      _logger.e('refreshFromCloud failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _enqueueCropSync(String cropId, String operation, Map<String, dynamic> payload) async {
    final int createdAt = DateTime.now().millisecondsSinceEpoch;
    await _databaseHelper.addToSyncQueue(
      DatabaseConstants.cropsTable,
      cropId,
      operation,
      <String, dynamic>{
        DatabaseConstants.columnId: cropId,
        DatabaseConstants.columnCreatedAt: createdAt,
        DatabaseConstants.columnPayload: payload,
      },
    );
  }

  Future<void> _enqueueImageUpload(String cropId, String localImagePath) async {
    final int createdAt = DateTime.now().millisecondsSinceEpoch;
    await _databaseHelper.addToSyncQueue(
      DatabaseConstants.cropsTable,
      cropId,
      'upload_image',
      <String, dynamic>{
        DatabaseConstants.columnId: '${cropId}_image_$createdAt',
        DatabaseConstants.columnCreatedAt: createdAt,
        DatabaseConstants.columnRecordId: cropId,
        DatabaseConstants.columnLocalImagePath: localImagePath,
      },
    );
  }

  Future<bool> _isOnline() async {
    final List<ConnectivityResult> statuses = await _connectivity.checkConnectivity();
    return statuses.any((ConnectivityResult value) => value != ConnectivityResult.none);
  }
}

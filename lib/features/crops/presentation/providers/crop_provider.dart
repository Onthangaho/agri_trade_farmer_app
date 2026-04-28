// lib/features/crops/presentation/providers/crop_provider.dart
/// Crop provider with SQLite-first persistence and Firestore sync.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/database/database_constants.dart';
import '../../../../shared/database/database_helper.dart';
import '../../domain/entities/crop_entity.dart';
import '../../domain/repositories/crop_repository.dart';
import '../../domain/use_cases/delete_crop_use_case.dart';
import '../../domain/use_cases/get_crops_use_case.dart';
import '../../domain/use_cases/save_crop_use_case.dart';
import '../../domain/use_cases/update_crop_use_case.dart';

class CropProvider extends ChangeNotifier {
  CropProvider({
    required GetCropsUseCase getCrops,
    required SaveCropUseCase saveCrop,
    required UpdateCropUseCase updateCrop,
    required DeleteCropUseCase deleteCrop,
    required CropRepository repository,
    DatabaseHelper? databaseHelper,
    FirebaseFirestore? firestore,
    Logger? logger,
  })  : _getCrops = getCrops,
        _saveCrop = saveCrop,
        _updateCrop = updateCrop,
        _deleteCrop = deleteCrop,
        _repository = repository,
        _dbHelper = databaseHelper,
        _firestore = firestore,
        _logger = logger ?? Logger();

  final GetCropsUseCase _getCrops;
  final SaveCropUseCase _saveCrop;
  final UpdateCropUseCase _updateCrop;
  final DeleteCropUseCase _deleteCrop;
  final CropRepository _repository;
  final DatabaseHelper? _dbHelper;
  final FirebaseFirestore? _firestore;
  final Logger _logger;

  List<CropEntity> _crops = <CropEntity>[];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  List<CropEntity> get crops => List<CropEntity>.unmodifiable(_crops);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get _useDirectPersistence => _dbHelper != null && _firestore != null;

  Future<void> loadCrops(String farmerId) async {
    if (farmerId.isEmpty) {
      _crops = <CropEntity>[];
      _isLoading = false;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (!_useDirectPersistence) {
      try {
        _crops = await _getCrops(farmerId);
        _errorMessage = null;
      } on SocketException {
        _errorMessage = 'Offline - showing saved crops.';
      } catch (error, stackTrace) {
        _errorMessage = 'Could not load crops. Please try again.';
        _logger.e('loadCrops (repository) failed', error: error, stackTrace: stackTrace);
      } finally {
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    final DatabaseHelper dbHelper = _dbHelper!;
    final FirebaseFirestore firestore = _firestore!;

    List<CropEntity> localCrops = <CropEntity>[];
    bool hasLocalFailure = false;
    bool hasRemoteFailure = false;

    try {
      final List<Map<String, dynamic>> localRows =
          await dbHelper.getCropsByFarmer(farmerId);
      localCrops = localRows.map(_fromMap).toList(growable: false);
      _crops = localCrops;
      notifyListeners();
    } catch (error, stackTrace) {
      hasLocalFailure = true;
      _logger.e(
        'loadCrops local read failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> remoteSnapshot =
          await firestore
              .collection('crops')
              .where('farmerId', isEqualTo: farmerId)
              .get();

      final List<CropEntity> remoteCrops =
          remoteSnapshot.docs.map(_fromFirestore).toList(growable: false);
      final Map<String, CropEntity> localById = <String, CropEntity>{
        for (final CropEntity crop in localCrops) crop.id: crop,
      };

      for (final CropEntity remoteCrop in remoteCrops) {
        final CropEntity? localMatch = localById[remoteCrop.id];
        if (localMatch != null && !localMatch.synced) {
          // Never overwrite newer local unsynced edits with stale cloud copies.
          continue;
        }
        await dbHelper.insertCrop(_toMap(remoteCrop, synced: 1));
      }

      _crops = mergeLocalAndRemoteCrops(
        localCrops: localCrops,
        remoteCrops: remoteCrops,
      );
    } on FirebaseException catch (error, stackTrace) {
      hasRemoteFailure = true;
      _logger.e(
        'loadCrops remote fetch failed',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      hasRemoteFailure = true;
      _logger.e(
        'loadCrops unexpected remote fetch failure',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (hasLocalFailure && hasRemoteFailure) {
        _errorMessage =
            'Could not refresh crops. Showing available saved data.';
      } else if (hasRemoteFailure && _crops.isNotEmpty) {
        _errorMessage = 'Showing offline data. Cloud refresh failed.';
      } else {
        _errorMessage = null;
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveCrop(CropEntity crop, {File? imageFile}) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final String cropId = crop.id.trim().isEmpty ? const Uuid().v4() : crop.id;
    final CropEntity cropToSave = crop.copyWith(id: cropId, synced: false);

    if (!_useDirectPersistence) {
      try {
        await _saveCrop(cropToSave, imageFile: imageFile);
        _upsertLocalCrop(cropToSave.copyWith(synced: true));
        _successMessage = 'Crop saved successfully.';
        return true;
      } on SocketException {
        _upsertLocalCrop(cropToSave);
        _successMessage = 'Saved offline. Will sync when connected.';
        return true;
      } catch (error, stackTrace) {
        _logger.e('saveCrop (repository) failed', error: error, stackTrace: stackTrace);
        _errorMessage = 'Could not save crop. Please try again.';
        return false;
      } finally {
        _isSaving = false;
        notifyListeners();
      }
    }

    final DatabaseHelper dbHelper = _dbHelper!;
    final FirebaseFirestore firestore = _firestore!;

    try {
      await dbHelper.insertCrop(_toMap(cropToSave, synced: 0));
      _upsertLocalCrop(cropToSave);
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.e('saveCrop local write failed', error: error, stackTrace: stackTrace);
      _errorMessage = 'Could not save crop locally.';
      _isSaving = false;
      notifyListeners();
      return false;
    }

    try {
      await firestore
          .collection('crops')
          .doc(cropId)
          .set(_toFirestore(cropToSave), SetOptions(merge: true));
      await dbHelper.markCropSynced(cropId);
      _upsertLocalCrop(cropToSave.copyWith(synced: true));
      _successMessage = 'Crop saved successfully.';
      return true;
    } on FirebaseException catch (error, stackTrace) {
      _logger.e('saveCrop Firestore save failed', error: error, stackTrace: stackTrace);
      _successMessage = 'Saved offline. Will sync when connected.';
      return true;
    } on SocketException catch (error, stackTrace) {
      _logger.e('saveCrop offline socket issue', error: error, stackTrace: stackTrace);
      _successMessage = 'Saved offline. Will sync when connected.';
      return true;
    } catch (error, stackTrace) {
      _logger.e('saveCrop unexpected save failure', error: error, stackTrace: stackTrace);
      _successMessage = 'Saved offline. Will sync when connected.';
      return true;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateCrop(CropEntity crop) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final CropEntity updatedCrop = crop.copyWith(synced: false);

    if (!_useDirectPersistence) {
      try {
        await _updateCrop(updatedCrop);
        _upsertLocalCrop(updatedCrop.copyWith(synced: true));
        _successMessage = 'Crop updated successfully.';
      } on SocketException {
        _upsertLocalCrop(updatedCrop);
        _successMessage = 'Updated offline. Will sync when connected.';
      } catch (error, stackTrace) {
        _logger.e('updateCrop (repository) failed', error: error, stackTrace: stackTrace);
        _errorMessage = 'Could not update crop. Please try again.';
      } finally {
        _isSaving = false;
        notifyListeners();
      }
      return;
    }

    final DatabaseHelper dbHelper = _dbHelper!;
    final FirebaseFirestore firestore = _firestore!;

    try {
      await dbHelper.updateCrop(updatedCrop.id, _toMap(updatedCrop, synced: 0));
      _upsertLocalCrop(updatedCrop);
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.e('updateCrop local update failed', error: error, stackTrace: stackTrace);
      _errorMessage = 'Could not update crop locally.';
      _isSaving = false;
      notifyListeners();
      return;
    }

    try {
      await firestore
          .collection('crops')
          .doc(updatedCrop.id)
          .set(_toFirestore(updatedCrop), SetOptions(merge: true));
      await dbHelper.markCropSynced(updatedCrop.id);
      _upsertLocalCrop(updatedCrop.copyWith(synced: true));
      _successMessage = 'Crop updated successfully.';
    } on FirebaseException catch (error, stackTrace) {
      _logger.e('updateCrop Firestore update failed', error: error, stackTrace: stackTrace);
      _successMessage = 'Updated offline. Will sync when connected.';
    } on SocketException catch (error, stackTrace) {
      _logger.e('updateCrop offline socket issue', error: error, stackTrace: stackTrace);
      _successMessage = 'Updated offline. Will sync when connected.';
    } catch (error, stackTrace) {
      _logger.e('updateCrop unexpected update failure', error: error, stackTrace: stackTrace);
      _successMessage = 'Updated offline. Will sync when connected.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCrop(String id) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final List<CropEntity> backup = List<CropEntity>.from(_crops);

    if (!_useDirectPersistence) {
      _crops = _crops.where((CropEntity item) => item.id != id).toList(growable: false);
      notifyListeners();
      try {
        await _deleteCrop(id);
        _successMessage = 'Crop deleted.';
        return true;
      } on SocketException {
        _successMessage = 'Deleted offline. Will sync when connected.';
        return true;
      } catch (error, stackTrace) {
        _logger.e('deleteCrop (repository) failed', error: error, stackTrace: stackTrace);
        _crops = backup;
        _errorMessage = 'Could not delete crop right now.';
        return false;
      } finally {
        _isSaving = false;
        notifyListeners();
      }
    }

    final DatabaseHelper dbHelper = _dbHelper!;
    final FirebaseFirestore firestore = _firestore!;

    try {
      await dbHelper.deleteCrop(id);
      _crops = _crops.where((CropEntity item) => item.id != id).toList(growable: false);
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.e('deleteCrop local delete failed', error: error, stackTrace: stackTrace);
      _errorMessage = 'Could not delete crop locally.';
      _isSaving = false;
      notifyListeners();
      return false;
    }

    try {
      await firestore.collection('crops').doc(id).delete();
      _successMessage = 'Crop deleted.';
      return true;
    } on FirebaseException catch (error, stackTrace) {
      _logger.e('deleteCrop Firestore delete failed', error: error, stackTrace: stackTrace);
      _successMessage = 'Deleted offline. Will sync when connected.';
      return true;
    } on SocketException catch (error, stackTrace) {
      _logger.e('deleteCrop offline socket issue', error: error, stackTrace: stackTrace);
      _successMessage = 'Deleted offline. Will sync when connected.';
      return true;
    } catch (error, stackTrace) {
      _logger.e('deleteCrop unexpected delete failure', error: error, stackTrace: stackTrace);
      _crops = backup;
      _errorMessage = 'Could not delete crop right now.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> syncPendingCrops() async {
    try {
      await _repository.syncPendingCrops();
    } catch (error, stackTrace) {
      _logger.e('syncPendingCrops failed', error: error, stackTrace: stackTrace);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  @visibleForTesting
  List<CropEntity> mergeLocalAndRemoteCrops({
    required List<CropEntity> localCrops,
    required List<CropEntity> remoteCrops,
  }) {
    final Map<String, CropEntity> mergedById = <String, CropEntity>{
      for (final CropEntity crop in remoteCrops) crop.id: crop,
    };
    for (final CropEntity localCrop in localCrops) {
      final CropEntity? existing = mergedById[localCrop.id];
      if (existing == null || !localCrop.synced) {
        mergedById[localCrop.id] = localCrop;
      }
    }
    final List<CropEntity> merged = mergedById.values.toList(growable: false);
    merged.sort((CropEntity a, CropEntity b) => b.listedAt.compareTo(a.listedAt));
    return merged;
  }

  void _upsertLocalCrop(CropEntity crop) {
    final int index = _crops.indexWhere((CropEntity item) => item.id == crop.id);
    if (index == -1) {
      _crops = <CropEntity>[crop, ..._crops];
      return;
    }
    final List<CropEntity> updated = List<CropEntity>.from(_crops);
    updated[index] = crop;
    _crops = updated;
  }

  Map<String, dynamic> _toMap(CropEntity crop, {required int synced}) {
    return <String, dynamic>{
      DatabaseConstants.columnId: crop.id,
      DatabaseConstants.columnFarmerId: crop.farmerId,
      DatabaseConstants.columnName: crop.name,
      DatabaseConstants.columnQuantity: crop.quantity,
      DatabaseConstants.columnUnit: crop.unit,
      DatabaseConstants.columnPricePerUnit: crop.pricePerUnit,
      DatabaseConstants.columnImageUrl: crop.imageUrl,
      DatabaseConstants.columnLocalImagePath: crop.localImagePath,
      DatabaseConstants.columnDescription: crop.description,
      DatabaseConstants.columnListedAt: crop.listedAt.millisecondsSinceEpoch,
      DatabaseConstants.columnExpiresAt: crop.expiresAt?.millisecondsSinceEpoch,
      DatabaseConstants.columnStatus: crop.status,
      DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      DatabaseConstants.columnSynced: synced,
    };
  }

  Map<String, dynamic> _toFirestore(CropEntity crop) {
    return <String, dynamic>{
      'farmerId': crop.farmerId,
      'name': crop.name,
      'quantity': crop.quantity,
      'unit': crop.unit,
      'pricePerUnit': crop.pricePerUnit,
      'imageUrl': crop.imageUrl,
      'description': crop.description,
      'listedAt': Timestamp.fromDate(crop.listedAt),
      'expiresAt': crop.expiresAt == null ? null : Timestamp.fromDate(crop.expiresAt!),
      'status': crop.status,
    };
  }

  CropEntity _fromMap(Map<String, dynamic> map) {
    return CropEntity(
      id: map[DatabaseConstants.columnId] as String? ?? '',
      farmerId: map[DatabaseConstants.columnFarmerId] as String? ?? '',
      name: map[DatabaseConstants.columnName] as String? ?? '',
      quantity: ((map[DatabaseConstants.columnQuantity] as num?) ?? 0).toDouble(),
      unit: map[DatabaseConstants.columnUnit] as String? ?? 'kg',
      pricePerUnit:
          ((map[DatabaseConstants.columnPricePerUnit] as num?) ?? 0).toDouble(),
      imageUrl: map[DatabaseConstants.columnImageUrl] as String?,
      localImagePath: map[DatabaseConstants.columnLocalImagePath] as String?,
      description: map[DatabaseConstants.columnDescription] as String?,
      listedAt: DateTime.fromMillisecondsSinceEpoch(
        ((map[DatabaseConstants.columnListedAt] as num?) ?? 0).toInt(),
      ),
      expiresAt: (map[DatabaseConstants.columnExpiresAt] as num?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (map[DatabaseConstants.columnExpiresAt] as num).toInt(),
            ),
      status: map[DatabaseConstants.columnStatus] as String? ?? 'active',
      synced: ((map[DatabaseConstants.columnSynced] as num?) ?? 0).toInt() == 1,
    );
  }

  CropEntity _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final Timestamp listedAtTs = data['listedAt'] as Timestamp? ?? Timestamp.now();
    final Timestamp? expiresAtTs = data['expiresAt'] as Timestamp?;

    return CropEntity(
      id: doc.id,
      farmerId: data['farmerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      quantity: ((data['quantity'] as num?) ?? 0).toDouble(),
      unit: data['unit'] as String? ?? 'kg',
      pricePerUnit: ((data['pricePerUnit'] as num?) ?? 0).toDouble(),
      imageUrl: data['imageUrl'] as String?,
      localImagePath: null,
      description: data['description'] as String?,
      listedAt: listedAtTs.toDate(),
      expiresAt: expiresAtTs?.toDate(),
      status: data['status'] as String? ?? 'active',
      synced: true,
    );
  }
}

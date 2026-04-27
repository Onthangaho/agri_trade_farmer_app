// lib/features/crops/presentation/providers/crop_provider.dart
/// Presentation provider for crop CRUD actions and screen state.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

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
  })  : _getCrops = getCrops,
        _saveCrop = saveCrop,
        _updateCrop = updateCrop,
        _deleteCrop = deleteCrop,
        _repository = repository;

  final GetCropsUseCase _getCrops;
  final SaveCropUseCase _saveCrop;
  final UpdateCropUseCase _updateCrop;
  final DeleteCropUseCase _deleteCrop;
  final CropRepository _repository;
  final Logger _logger = Logger();

  List<CropEntity> _crops = <CropEntity>[];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<CropEntity> get crops => List<CropEntity>.unmodifiable(_crops);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> loadCrops(String farmerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _crops = await _getCrops(farmerId);
      _errorMessage = null;
    } on SocketException {
      _errorMessage = 'Offline - showing saved crops.';
    } catch (error, stackTrace) {
      _errorMessage = 'Could not load crops. Please try again.';
      _logger.e('loadCrops failed', error: error, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveCrop(CropEntity crop, {File? imageFile}) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _saveCrop(crop, imageFile: imageFile);
      _crops = <CropEntity>[crop, ..._crops.where((CropEntity item) => item.id != crop.id)];
      _errorMessage = null;
    } on SocketException {
      _crops = <CropEntity>[crop, ..._crops.where((CropEntity item) => item.id != crop.id)];
      _errorMessage = 'No internet. Crop saved offline.';
    } catch (error, stackTrace) {
      _errorMessage = 'Could not save crop. Please try again.';
      _logger.e('saveCrop failed', error: error, stackTrace: stackTrace);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateCrop(CropEntity crop) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _updateCrop(crop);
      _crops = _crops
          .map((CropEntity item) => item.id == crop.id ? crop : item)
          .toList(growable: false);
      _errorMessage = null;
    } on SocketException {
      _crops = _crops
          .map((CropEntity item) => item.id == crop.id ? crop : item)
          .toList(growable: false);
      _errorMessage = 'No internet. Changes saved offline.';
    } catch (error, stackTrace) {
      _errorMessage = 'Could not update crop. Please try again.';
      _logger.e('updateCrop failed', error: error, stackTrace: stackTrace);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCrop(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final List<CropEntity> backup = List<CropEntity>.from(_crops);
    _crops = _crops.where((CropEntity item) => item.id != id).toList(growable: false);
    notifyListeners();

    try {
      await _deleteCrop(id);
      _errorMessage = null;
      return true;
    } on SocketException {
      _errorMessage = 'No internet. Deletion queued for sync.';
      return true;
    } catch (error, stackTrace) {
      _crops = backup;
      _errorMessage = 'Could not delete crop. Please try again.';
      _logger.e('deleteCrop failed', error: error, stackTrace: stackTrace);
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
}

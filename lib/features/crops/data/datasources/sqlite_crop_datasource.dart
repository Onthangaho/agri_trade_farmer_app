// lib/features/crops/data/datasources/sqlite_crop_datasource.dart
// Local SQLite datasource for crop persistence and sync status operations.

import 'package:logger/logger.dart';

import '../../../../shared/database/database_helper.dart';
import '../models/crop_model.dart';

class SqliteCropDataSource {
  SqliteCropDataSource({
    required DatabaseHelper databaseHelper,
    Logger? logger,
  })  : _databaseHelper = databaseHelper,
        _logger = logger ?? Logger();

  final DatabaseHelper _databaseHelper;
  final Logger _logger;

  Future<void> saveCrop(CropModel crop) async {
    try {
      await _databaseHelper.insertCrop(
        crop.toJson(updatedAtMillis: DateTime.now().millisecondsSinceEpoch),
      );
    } catch (error, stackTrace) {
      _logger.e('SQLite saveCrop failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<CropModel>> getCropsByFarmer(String farmerId) async {
    try {
      final List<Map<String, dynamic>> rows = await _databaseHelper.getCropsByFarmer(farmerId);
      return rows.map(CropModel.fromJson).toList();
    } catch (error, stackTrace) {
      _logger.e('SQLite getCropsByFarmer failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<CropModel?> getCropById(String id) async {
    try {
      final Map<String, dynamic>? row = await _databaseHelper.getCropById(id);
      if (row == null) {
        return null;
      }
      return CropModel.fromJson(row);
    } catch (error, stackTrace) {
      _logger.e('SQLite getCropById failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateCrop(CropModel crop) async {
    try {
      await _databaseHelper.updateCrop(
        crop.id,
        crop.toJson(updatedAtMillis: DateTime.now().millisecondsSinceEpoch),
      );
    } catch (error, stackTrace) {
      _logger.e('SQLite updateCrop failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteCrop(String id) async {
    try {
      await _databaseHelper.deleteCrop(id);
    } catch (error, stackTrace) {
      _logger.e('SQLite deleteCrop failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<CropModel>> getUnsyncedCrops() async {
    try {
      final List<Map<String, dynamic>> rows = await _databaseHelper.getUnsyncedCrops();
      return rows.map(CropModel.fromJson).toList();
    } catch (error, stackTrace) {
      _logger.e('SQLite getUnsyncedCrops failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> markCropSynced(String id) async {
    try {
      await _databaseHelper.markCropSynced(id);
    } catch (error, stackTrace) {
      _logger.e('SQLite markCropSynced failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }
}

// lib/features/crops/domain/repositories/crop_repository.dart
/// Domain contract for crop inventory persistence and synchronization operations.

import '../entities/crop_entity.dart';
import 'dart:io';

abstract class CropRepository {
  Future<void> saveCrop(CropEntity crop, {File? imageFile});
  Future<List<CropEntity>> getCrops(String farmerId);
  Future<CropEntity?> getCropById(String id);
  Future<void> updateCrop(CropEntity crop);
  Future<void> deleteCrop(String id);
  Future<void> syncPendingCrops();
}

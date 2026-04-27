// lib/features/farms/domain/repositories/farm_repository.dart
/// Contract for farm persistence and location tagging operations.

import '../entities/farm_entity.dart';

abstract class FarmRepository {
  Future<void> saveFarm(FarmEntity farm);
  Future<FarmEntity?> getFarm(String farmerId);
  Future<void> updateFarmLocation(String farmId, double lat, double lng, String? address);
}

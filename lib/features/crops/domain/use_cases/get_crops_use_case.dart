// lib/features/crops/domain/use_cases/get_crops_use_case.dart
/// Use case for retrieving farmer crop listings.

import '../entities/crop_entity.dart';
import '../repositories/crop_repository.dart';

class GetCropsUseCase {
  const GetCropsUseCase({required CropRepository repository})
      : _repository = repository;

  final CropRepository _repository;

  Future<List<CropEntity>> call(String farmerId) {
    return _repository.getCrops(farmerId);
  }
}

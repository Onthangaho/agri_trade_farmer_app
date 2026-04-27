// lib/features/crops/domain/use_cases/update_crop_use_case.dart
/// Use case for updating an existing crop listing.

import '../entities/crop_entity.dart';
import '../repositories/crop_repository.dart';

class UpdateCropUseCase {
  const UpdateCropUseCase({required CropRepository repository})
      : _repository = repository;

  final CropRepository _repository;

  Future<void> call(CropEntity crop) {
    return _repository.updateCrop(crop);
  }
}

// lib/features/crops/domain/use_cases/delete_crop_use_case.dart
/// Use case for deleting a crop listing.

import '../repositories/crop_repository.dart';

class DeleteCropUseCase {
  const DeleteCropUseCase({required CropRepository repository})
      : _repository = repository;

  final CropRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteCrop(id);
  }
}

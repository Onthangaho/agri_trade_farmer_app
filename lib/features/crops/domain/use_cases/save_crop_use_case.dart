// lib/features/crops/domain/use_cases/save_crop_use_case.dart
/// Use case for creating a new crop listing.

import 'dart:io';

import '../entities/crop_entity.dart';
import '../repositories/crop_repository.dart';

class SaveCropUseCase {
  const SaveCropUseCase({required CropRepository repository})
      : _repository = repository;

  final CropRepository _repository;

  Future<void> call(CropEntity crop, {File? imageFile}) {
    return _repository.saveCrop(crop, imageFile: imageFile);
  }
}

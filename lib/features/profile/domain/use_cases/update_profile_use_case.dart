// lib/features/profile/domain/use_cases/update_profile_use_case.dart
/// Use case for updating a farmer profile.

import '../../../auth/domain/entities/farmer_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase({required ProfileRepository repository})
      : _repository = repository;

  final ProfileRepository _repository;

  Future<void> call(FarmerEntity farmer) {
    return _repository.updateProfile(farmer);
  }
}

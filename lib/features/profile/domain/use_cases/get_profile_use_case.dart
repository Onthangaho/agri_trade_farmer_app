// lib/features/profile/domain/use_cases/get_profile_use_case.dart
/// Use case for loading a farmer profile.

import '../../../auth/domain/entities/farmer_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase {
  const GetProfileUseCase({required ProfileRepository repository})
      : _repository = repository;

  final ProfileRepository _repository;

  Future<FarmerEntity> call(String farmerId) {
    return _repository.getProfile(farmerId);
  }
}

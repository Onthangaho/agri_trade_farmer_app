// lib/features/profile/domain/repositories/profile_repository.dart
/// Domain contract for farmer profile data operations.

import 'dart:io';

import '../../../auth/domain/entities/farmer_entity.dart';

abstract class ProfileRepository {
  Future<FarmerEntity> getProfile(String farmerId);
  Future<void> updateProfile(FarmerEntity farmer);
  Future<String> updateProfileImage(String farmerId, File imageFile);
}

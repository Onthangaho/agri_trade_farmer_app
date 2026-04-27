// lib/features/profile/presentation/providers/profile_provider.dart
/// Presentation-layer profile provider for loading and updating farmer data.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../auth/domain/entities/farmer_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/use_cases/get_profile_use_case.dart';
import '../../domain/use_cases/update_profile_use_case.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    required GetProfileUseCase getProfile,
    required UpdateProfileUseCase updateProfile,
    required ProfileRepository profileRepository,
  })  : _getProfile = getProfile,
        _updateProfile = updateProfile,
        _profileRepository = profileRepository;

  final GetProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;
  final ProfileRepository _profileRepository;
  final Logger _logger = Logger();

  FarmerEntity? _farmer;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  FarmerEntity? get farmer => _farmer;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile(String farmerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _farmer = await _getProfile(farmerId);
      _errorMessage = null;
    } on SocketException {
      _errorMessage = 'No internet. Showing saved profile.';
    } catch (error, stackTrace) {
      _errorMessage = 'Could not load profile. Please try again.';
      _logger.e('loadProfile failed', error: error, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(FarmerEntity farmer) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _updateProfile(farmer);
      _farmer = farmer;
      _errorMessage = null;
    } on SocketException {
      _farmer = farmer;
      _errorMessage = 'No internet. Changes saved offline.';
    } catch (error, stackTrace) {
      _errorMessage = 'Could not update profile. Please try again.';
      _logger.e('updateProfile failed', error: error, stackTrace: stackTrace);
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> updateImage(File imageFile) async {
    final FarmerEntity? current = _farmer;
    if (current == null) {
      _errorMessage = 'Load your profile before uploading an image.';
      notifyListeners();
      return;
    }

    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String imageUrl = await _profileRepository.updateProfileImage(current.id, imageFile);
      _farmer = current.copyWith(profileImageUrl: imageUrl);
      _errorMessage = null;
    } on SocketException {
      _errorMessage = 'No internet. Image will sync when connected.';
    } catch (error, stackTrace) {
      _errorMessage = 'Could not update profile image. Please try again.';
      _logger.e('updateImage failed', error: error, stackTrace: stackTrace);
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

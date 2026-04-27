// lib/features/farms/presentation/providers/farm_provider.dart
/// Presentation provider for farm loading, saving, and GPS tagging.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/location_service.dart';
import '../../domain/entities/farm_entity.dart';
import '../../domain/repositories/farm_repository.dart';

class FarmProvider extends ChangeNotifier {
  FarmProvider({
    required FarmRepository farmRepository,
    required LocationService locationService,
  })  : _farmRepository = farmRepository,
        _locationService = locationService;

  final FarmRepository _farmRepository;
  final LocationService _locationService;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  FarmEntity? _farm;
  bool _isLoading = false;
  bool _isTagging = false;
  String? _errorMessage;
  bool _locationTagged = false;

  FarmEntity? get farm => _farm;
  bool get isLoading => _isLoading;
  bool get isTagging => _isTagging;
  String? get errorMessage => _errorMessage;
  bool get locationTagged => _locationTagged;

  Future<void> loadFarm(String farmerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _farm = await _farmRepository.getFarm(farmerId);
      _locationTagged = _farm?.isTagged ?? false;
      _errorMessage = null;
    } catch (error, stackTrace) {
      _errorMessage = 'Could not load farm details.';
      _logger.e('loadFarm failed', error: error, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveFarm(FarmEntity farm) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _farmRepository.saveFarm(farm);
      _farm = farm;
      _locationTagged = _farm?.isTagged ?? false;
      _errorMessage = null;
    } catch (error, stackTrace) {
      _errorMessage = 'Could not save farm details.';
      _logger.e('saveFarm failed', error: error, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> tagLocation(BuildContext context) async {
    final FarmEntity? currentFarm = _farm;
    if (currentFarm == null) {
      _errorMessage = 'Add your farm first before tagging location.';
      notifyListeners();
      return;
    }

    _isTagging = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition(context);
      if (position == null) {
        _errorMessage = 'Location was not captured.';
        return;
      }

      final String address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      await _farmRepository.updateFarmLocation(
        currentFarm.id,
        position.latitude,
        position.longitude,
        address,
      );

      _farm = currentFarm.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        updatedAt: DateTime.now(),
      );
      _locationTagged = true;
      _errorMessage = null;
    } catch (error, stackTrace) {
      _errorMessage = 'Could not tag farm location. Please try again.';
      _logger.e('tagLocation failed', error: error, stackTrace: stackTrace);
    } finally {
      _isTagging = false;
      notifyListeners();
    }
  }

  FarmEntity createDraftFarm({
    required String farmerId,
    required String name,
    double? sizeHa,
  }) {
    return FarmEntity(
      id: _uuid.v4(),
      farmerId: farmerId,
      name: name,
      sizeHa: sizeHa,
      updatedAt: DateTime.now(),
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

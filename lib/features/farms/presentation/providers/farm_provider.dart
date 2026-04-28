import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/location_service.dart';
import '../../../../shared/database/database_constants.dart';
import '../../../../shared/database/database_helper.dart';
import '../../domain/entities/farm_entity.dart';
import '../../domain/repositories/farm_repository.dart';

class FarmProvider extends ChangeNotifier {
  FarmProvider({
    required FarmRepository farmRepository,
    required LocationService locationService,
    FirebaseFirestore? firestore,
    DatabaseHelper? databaseHelper,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _logger = logger ?? Logger();

  final FirebaseFirestore _firestore;
  final DatabaseHelper _databaseHelper;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  Map<String, dynamic>? _farmData;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isTagging = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isTagging => _isTagging;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasFarm => _farmData != null;
  bool get hasLocation =>
      (_farmData?['latitude'] != null) && (_farmData?['longitude'] != null);
  double? get latitude => (_farmData?['latitude'] as num?)?.toDouble();
  double? get longitude => (_farmData?['longitude'] as num?)?.toDouble();
  String get farmName => (_farmData?['name'] as String?) ?? '';
  String get address => (_farmData?['address'] as String?) ?? '';
  bool get locationTagged => hasLocation;

  FarmEntity? get farm {
    final Map<String, dynamic>? data = _farmData;
    if (data == null) {
      return null;
    }
    return FarmEntity(
      id: (data['id'] as String?) ?? '',
      farmerId: (data['farmerId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      sizeHa: (data['sizeHa'] as num?)?.toDouble(),
      address: data['address'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Future<void> loadFarm(String userId) async {
    if (userId.isEmpty) {
      _farmData = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('farms').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        _farmData = <String, dynamic>{
          'id': doc.id,
          ...doc.data()!,
        };
      } else {
        _farmData = null;
      }
    } on FirebaseException catch (error, stackTrace) {
      _farmData = null;
      _errorMessage = 'Could not load farm details right now.';
      _logger.e('loadFarm Firebase failed', error: error, stackTrace: stackTrace);
    } catch (error, stackTrace) {
      _farmData = null;
      _errorMessage = 'Could not load farm details right now.';
      _logger.e('loadFarm failed', error: error, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveFarm(dynamic userIdOrFarm, [String? farmName, double? sizeHa]) async {
    String userId;
    String resolvedFarmName;
    double? resolvedSizeHa;
    if (userIdOrFarm is FarmEntity) {
      userId = userIdOrFarm.farmerId;
      resolvedFarmName = userIdOrFarm.name;
      resolvedSizeHa = userIdOrFarm.sizeHa;
    } else {
      userId = (userIdOrFarm as String?) ?? '';
      resolvedFarmName = farmName ?? '';
      resolvedSizeHa = sizeHa;
    }

    if (userId.isEmpty) {
      _errorMessage = 'Please log in first.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final Map<String, dynamic> data = <String, dynamic>{
      'farmerId': userId,
      'name': resolvedFarmName.trim(),
      'sizeHa': resolvedSizeHa,
      'updatedAt': Timestamp.now(),
    };

    try {
      await _firestore.collection('farms').doc(userId).set(data, SetOptions(merge: true));

      await _databaseHelper.insertFarm(<String, dynamic>{
        DatabaseConstants.columnId: userId,
        DatabaseConstants.columnFarmerId: userId,
        DatabaseConstants.columnName: resolvedFarmName.trim(),
        DatabaseConstants.columnLatitude: _farmData?['latitude'],
        DatabaseConstants.columnLongitude: _farmData?['longitude'],
        DatabaseConstants.columnSizeHa: resolvedSizeHa,
        DatabaseConstants.columnAddress: _farmData?['address'],
        DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        DatabaseConstants.columnSynced: 1,
      });

      _farmData = <String, dynamic>{
        ...?_farmData,
        'id': userId,
        ...data,
      };
      _successMessage = 'Farm details saved successfully.';
      return true;
    } on FirebaseException catch (error, stackTrace) {
      _errorMessage = 'Could not save farm details.';
      _logger.e('saveFarm Firebase failed', error: error, stackTrace: stackTrace);
      return false;
    } catch (error, stackTrace) {
      _errorMessage = 'Could not save farm details.';
      _logger.e('saveFarm failed', error: error, stackTrace: stackTrace);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> tagLocation(dynamic userIdOrContext) async {
    final String userId = userIdOrContext is String
        ? userIdOrContext
        : ((_farmData?['farmerId'] as String?) ?? '');
    if (userId.isEmpty) {
      _errorMessage = 'Add your farm first before tagging location.';
      notifyListeners();
      return false;
    }
    _isTagging = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Please enable GPS in your phone settings.';
        return false;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _errorMessage = 'Location permission denied. Please allow in Settings.';
        return false;
      }

      const LocationSettings settings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      );
      final Position pos =
          await Geolocator.getCurrentPosition(locationSettings: settings);

      final Map<String, dynamic> data = <String, dynamic>{
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'address': 'Lat: ${pos.latitude.toStringAsFixed(4)}, '
            'Long: ${pos.longitude.toStringAsFixed(4)}',
        'locationTaggedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('farms')
          .doc(userId)
          .set(data, SetOptions(merge: true));

      _farmData = <String, dynamic>{
        ...?_farmData,
        'id': userId,
        'farmerId': userId,
        ...data,
      };
      _successMessage = 'Farm location tagged successfully!';
      return true;
    } on TimeoutException {
      _errorMessage = 'GPS timed out. Go outside and try again.';
      return false;
    } catch (error, stackTrace) {
      _logger.e('tagLocation failed', error: error, stackTrace: stackTrace);
      _errorMessage = 'Could not get location. Please try again.';
      return false;
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

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }
}

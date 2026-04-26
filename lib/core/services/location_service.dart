// lib/core/services/location_service.dart
/// Location service placeholder for future GPS tagging flows.

import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService();

  Future<Position> getCurrentPosition() async {
    return Geolocator.getCurrentPosition();
  }
}

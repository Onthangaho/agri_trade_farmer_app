// lib/core/services/connectivity_service.dart
/// Service that exposes the current network state to the app.

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> isOnline() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    return results.any((ConnectivityResult result) => result != ConnectivityResult.none);
  }
}

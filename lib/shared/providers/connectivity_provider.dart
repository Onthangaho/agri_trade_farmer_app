// lib/shared/providers/connectivity_provider.dart
/// Presentation-layer connectivity state for offline/online banners.

import 'package:flutter/foundation.dart';

import '../../core/services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider({ConnectivityService? connectivityService})
      : _connectivityService = connectivityService ?? ConnectivityService();

  final ConnectivityService _connectivityService;

  bool _isOnline = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> refreshStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _isOnline = await _connectivityService.isOnline();
    } catch (error) {
      _errorMessage = 'Unable to check connectivity.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

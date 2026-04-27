// lib/shared/providers/connectivity_provider.dart
/// Presentation-layer connectivity state for offline/online banners.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import 'sync_provider.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider({
    ConnectivityService? connectivityService,
    SyncService? syncService,
    SyncProvider? syncProvider,
  })  : _connectivityService = connectivityService ?? ConnectivityService(),
        _syncService = syncService,
        _syncProvider = syncProvider {
    _subscription = Connectivity().onConnectivityChanged.listen(_handleConnectivityChanged);
    unawaited(refreshStatus());
  }

  final ConnectivityService _connectivityService;
  final SyncService? _syncService;
  final SyncProvider? _syncProvider;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

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
      final bool wasOnline = _isOnline;
      final bool isOnlineNow = await _connectivityService.isOnline();
      _isOnline = isOnlineNow;
      notifyListeners();
      if (!wasOnline && isOnlineNow) {
        unawaited(_onConnectionRestored());
      }
    } catch (error) {
      _errorMessage = 'Unable to check connectivity.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleConnectivityChanged(List<ConnectivityResult> results) async {
    final bool wasOnline = _isOnline;
    final bool nowOnline = results.any((ConnectivityResult result) => result != ConnectivityResult.none);
    _isOnline = nowOnline;
    notifyListeners();

    if (!wasOnline && nowOnline) {
      await _onConnectionRestored();
    }
  }

  Future<void> _onConnectionRestored() async {
    final SyncService? syncService = _syncService;
    final SyncProvider? syncProvider = _syncProvider;
    if (syncService == null || syncProvider == null) {
      return;
    }

    final SyncResult result = await syncService.syncAllPending();
    syncProvider.applySyncResult(result);
    await syncProvider.updatePendingCount();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

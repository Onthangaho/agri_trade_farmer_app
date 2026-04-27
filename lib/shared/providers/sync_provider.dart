// lib/shared/providers/sync_provider.dart
/// Presentation state for background sync progress and badge counts.

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../core/services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  SyncProvider({required SyncService syncService}) : _syncService = syncService;

  final SyncService _syncService;
  final Logger _logger = Logger();

  bool _isSyncing = false;
  int _pendingCount = 0;
  DateTime? _lastSyncTime;
  SyncResult? _lastSyncResult;

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  DateTime? get lastSyncTime => _lastSyncTime;
  SyncResult? get lastSyncResult => _lastSyncResult;

  Future<void> startSync() async {
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final SyncResult result = await _syncService.syncAllPending();
      applySyncResult(result);
      await updatePendingCount();
    } catch (error, stackTrace) {
      _logger.e('startSync failed', error: error, stackTrace: stackTrace);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> updatePendingCount() async {
    try {
      _pendingCount = await _syncService.getPendingCount();
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.e('updatePendingCount failed', error: error, stackTrace: stackTrace);
    }
  }

  void applySyncResult(SyncResult result) {
    _lastSyncResult = result;
    _lastSyncTime = result.syncedAt;
    notifyListeners();
  }
}
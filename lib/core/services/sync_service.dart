// lib/core/services/sync_service.dart
/// Coordinates queued sync work between local storage and cloud services.

import '../network/dio_client.dart';
import 'connectivity_service.dart';
import '../../shared/database/database_helper.dart';

class SyncService {
  SyncService({
    required DatabaseHelper databaseHelper,
    required ConnectivityService connectivityService,
    required DioClient dioClient,
  })  : _databaseHelper = databaseHelper,
        _connectivityService = connectivityService,
        _dioClient = dioClient;

  final DatabaseHelper _databaseHelper;
  final ConnectivityService _connectivityService;
  final DioClient _dioClient;

  DatabaseHelper get databaseHelper => _databaseHelper;
  ConnectivityService get connectivityService => _connectivityService;
  DioClient get dioClient => _dioClient;
}

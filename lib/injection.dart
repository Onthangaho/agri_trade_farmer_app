// lib/injection.dart
/// Dependency injection container for AgriTrade.

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'core/services/camera_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/location_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/sync_service.dart';
import 'shared/database/database_helper.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  if (!getIt.isRegistered<DioClient>()) {
    getIt.registerSingleton<DioClient>(DioClient());
  }

  if (!getIt.isRegistered<ConnectivityService>()) {
    getIt.registerSingleton<ConnectivityService>(ConnectivityService());
  }

  if (!getIt.isRegistered<DatabaseHelper>()) {
    getIt.registerSingleton<DatabaseHelper>(DatabaseHelper());
  }

  if (!getIt.isRegistered<SyncService>()) {
    getIt.registerSingleton<SyncService>(
      SyncService(
        databaseHelper: getIt<DatabaseHelper>(),
        connectivityService: getIt<ConnectivityService>(),
        dioClient: getIt<DioClient>(),
      ),
    );
  }

  if (!getIt.isRegistered<CameraService>()) {
    getIt.registerSingleton<CameraService>(CameraService());
  }

  if (!getIt.isRegistered<LocationService>()) {
    getIt.registerSingleton<LocationService>(LocationService());
  }

  if (!getIt.isRegistered<StorageService>()) {
    getIt.registerSingleton<StorageService>(
      StorageService(dioClient: getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<SharedPreferences>()) {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  }

  // TODO: Register feature repositories, use cases, and presentation providers as each feature is built.
  // TODO: Add auth data sources, repository implementation, and auth use cases.
  // TODO: Add crop data sources, repository implementation, and crop use cases.
  // TODO: Add farm data sources, repository implementation, and farm use cases.
  // TODO: Add profile data sources, repository implementation, and profile use cases.
  // TODO: Add marketplace data sources, repository implementation, and marketplace use cases.
}

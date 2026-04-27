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
import 'features/crops/data/datasources/firestore_crop_datasource.dart';
import 'features/crops/data/datasources/sqlite_crop_datasource.dart';
import 'features/crops/data/repositories/crop_repository_impl.dart';
import 'features/crops/domain/repositories/crop_repository.dart';
import 'features/crops/domain/use_cases/delete_crop_use_case.dart';
import 'features/crops/domain/use_cases/get_crops_use_case.dart';
import 'features/crops/domain/use_cases/save_crop_use_case.dart';
import 'features/crops/domain/use_cases/update_crop_use_case.dart';
import 'features/crops/presentation/providers/crop_provider.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/domain/use_cases/get_profile_use_case.dart';
import 'features/profile/domain/use_cases/update_profile_use_case.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
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
      StorageService(),
    );
  }

  if (!getIt.isRegistered<SharedPreferences>()) {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  }

  if (!getIt.isRegistered<ProfileRepository>()) {
    getIt.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(databaseHelper: getIt<DatabaseHelper>()),
    );
  }

  if (!getIt.isRegistered<SqliteCropDataSource>()) {
    getIt.registerLazySingleton<SqliteCropDataSource>(
      () => SqliteCropDataSource(databaseHelper: getIt<DatabaseHelper>()),
    );
  }

  if (!getIt.isRegistered<FirestoreCropDataSource>()) {
    getIt.registerLazySingleton<FirestoreCropDataSource>(
      FirestoreCropDataSource.new,
    );
  }

  if (!getIt.isRegistered<CropRepository>()) {
    getIt.registerLazySingleton<CropRepository>(
      () => CropRepositoryImpl(
        sqliteDataSource: getIt<SqliteCropDataSource>(),
        firestoreDataSource: getIt<FirestoreCropDataSource>(),
        databaseHelper: getIt<DatabaseHelper>(),
        storageService: getIt<StorageService>(),
      ),
    );
  }

  if (!getIt.isRegistered<SaveCropUseCase>()) {
    getIt.registerLazySingleton<SaveCropUseCase>(
      () => SaveCropUseCase(repository: getIt<CropRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCropsUseCase>()) {
    getIt.registerLazySingleton<GetCropsUseCase>(
      () => GetCropsUseCase(repository: getIt<CropRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateCropUseCase>()) {
    getIt.registerLazySingleton<UpdateCropUseCase>(
      () => UpdateCropUseCase(repository: getIt<CropRepository>()),
    );
  }

  if (!getIt.isRegistered<DeleteCropUseCase>()) {
    getIt.registerLazySingleton<DeleteCropUseCase>(
      () => DeleteCropUseCase(repository: getIt<CropRepository>()),
    );
  }

  if (!getIt.isRegistered<CropProvider>()) {
    getIt.registerFactory<CropProvider>(
      () => CropProvider(
        getCrops: getIt<GetCropsUseCase>(),
        saveCrop: getIt<SaveCropUseCase>(),
        updateCrop: getIt<UpdateCropUseCase>(),
        deleteCrop: getIt<DeleteCropUseCase>(),
        repository: getIt<CropRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetProfileUseCase>()) {
    getIt.registerLazySingleton<GetProfileUseCase>(
      () => GetProfileUseCase(repository: getIt<ProfileRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateProfileUseCase>()) {
    getIt.registerLazySingleton<UpdateProfileUseCase>(
      () => UpdateProfileUseCase(repository: getIt<ProfileRepository>()),
    );
  }

  if (!getIt.isRegistered<ProfileProvider>()) {
    getIt.registerFactory<ProfileProvider>(
      () => ProfileProvider(
        getProfile: getIt<GetProfileUseCase>(),
        updateProfile: getIt<UpdateProfileUseCase>(),
        profileRepository: getIt<ProfileRepository>(),
      ),
    );
  }

  // TODO: Add auth data sources, repository implementation, and auth use cases.
  // TODO: Add farm data sources, repository implementation, and farm use cases.
  // TODO: Add marketplace data sources, repository implementation, and marketplace use cases.
}

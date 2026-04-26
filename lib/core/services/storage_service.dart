// lib/core/services/storage_service.dart
/// Storage service placeholder for future Firebase Storage uploads.

import '../network/dio_client.dart';

class StorageService {
  StorageService({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  DioClient get dioClient => _dioClient;
}

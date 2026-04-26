// lib/core/network/dio_client.dart
/// Lightweight Dio client wrapper for the project's network layer.

import 'package:dio/dio.dart';

class DioClient {
  DioClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Dio get dio => _dio;
}

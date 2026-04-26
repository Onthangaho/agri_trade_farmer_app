// lib/core/services/camera_service.dart
/// Camera service placeholder for future image capture flows.

import 'package:camera/camera.dart';

class CameraService {
  CameraService();

  Future<CameraDescription?> getFirstCamera() async {
    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) {
      return null;
    }
    return cameras.first;
  }
}

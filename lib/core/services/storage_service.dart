// lib/core/services/storage_service.dart
/// Firebase Storage uploads for crop and profile images.

import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? firebaseStorage})
      : _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  final FirebaseStorage _firebaseStorage;

  CropImageUploadTask uploadCropImage(String cropId, File imageFile) {
    final Reference ref = _firebaseStorage.ref().child('crops/$cropId/image.jpg');
    final UploadTask uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final Stream<double> progress = uploadTask.snapshotEvents.map((TaskSnapshot snapshot) {
      final int total = snapshot.totalBytes;
      if (total == 0) {
        return 0;
      }
      return snapshot.bytesTransferred / total;
    });

    final Future<String> downloadUrl = uploadTask.then((TaskSnapshot snapshot) async {
      return snapshot.ref.getDownloadURL();
    }).catchError((Object error) {
      if (error is FirebaseException) {
        throw StorageServiceException(
          message: 'Crop image upload failed.',
          cause: error,
        );
      }

      throw StorageServiceException(
        message: 'Unexpected crop image upload failure.',
        cause: error,
      );
    });

    return CropImageUploadTask(progress: progress, downloadUrl: downloadUrl);
  }

  Future<String> uploadProfileImage(String farmerId, File imageFile) async {
    try {
      final Reference ref = _firebaseStorage.ref().child('farmers/$farmerId/profile.jpg');
      final TaskSnapshot snapshot = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return snapshot.ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw StorageServiceException(
        message: 'Profile image upload failed.',
        cause: error,
      );
    } catch (error) {
      throw StorageServiceException(
        message: 'Unexpected profile image upload failure.',
        cause: error,
      );
    }
  }
}

class CropImageUploadTask {
  CropImageUploadTask({required this.progress, required this.downloadUrl});

  final Stream<double> progress;
  final Future<String> downloadUrl;
}

class StorageServiceException implements Exception {
  StorageServiceException({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    return 'StorageServiceException(message: $message, cause: $cause)';
  }
}

// lib/core/services/camera_service.dart
/// Camera permission, picker, and image compression orchestration.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraService({ImagePicker? imagePicker}) : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<bool> showExplanationDialog(BuildContext context) async {
    final bool? allowed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera needed'),
          content: const Text(
            'AgriTrade uses your camera so buyers can see your crops clearly.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );

    return allowed ?? false;
  }

  Future<bool> requestPermission() async {
    final PermissionStatus status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> handlePermanentlyDenied(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission required'),
          content: const Text(
            'Camera access is permanently denied. Open settings to enable it.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );
  }

  Future<File?> pickImage(BuildContext context) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return null;
    }

    final XFile? picked = await _imagePicker.pickImage(source: source);
    if (picked == null) {
      return null;
    }

    return File(picked.path);
  }

  Future<File?> compressImage(File original) async {
    final int originalSize = await original.length();
    if (originalSize <= 200 * 1024) {
      return original;
    }

    final Directory tempDirectory = await getTemporaryDirectory();
    File currentFile = original;
    int quality = 85;

    while (quality >= 45) {
      final String targetPath = path.join(
        tempDirectory.path,
        'crop_${DateTime.now().microsecondsSinceEpoch}_q$quality.jpg',
      );

      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        currentFile.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
        keepExif: true,
      );

      if (compressedXFile == null) {
        break;
      }

      currentFile = File(compressedXFile.path);
      if (await currentFile.length() <= 200 * 1024) {
        return currentFile;
      }

      quality -= 10;
    }

    return currentFile;
  }

  Future<File?> captureAndCompress(BuildContext context) async {
    final bool shouldContinue = await showExplanationDialog(context);
    if (!context.mounted) {
      return null;
    }
    if (!shouldContinue) {
      return null;
    }

    final PermissionStatus currentStatus = await Permission.camera.status;
    if (!context.mounted) {
      return null;
    }
    if (currentStatus.isPermanentlyDenied) {
      await handlePermanentlyDenied(context);
      return null;
    }

    if (!currentStatus.isGranted) {
      final bool granted = await requestPermission();
      if (!context.mounted) {
        return null;
      }
      if (!granted) {
        final PermissionStatus statusAfterRequest = await Permission.camera.status;
        if (!context.mounted) {
          return null;
        }
        if (statusAfterRequest.isPermanentlyDenied) {
          await handlePermanentlyDenied(context);
        }
        return null;
      }
    }

    final File? picked = await pickImage(context);
    if (picked == null) {
      return null;
    }

    return compressImage(picked);
  }
}

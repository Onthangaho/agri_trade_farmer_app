// lib/features/profile/data/repositories/profile_repository_impl.dart
/// Data-layer profile repository with offline-first SQLite reads/writes and Firebase sync.

import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logger/logger.dart';

import '../../../../shared/database/database_constants.dart';
import '../../../../shared/database/database_helper.dart';
import '../../../auth/data/models/farmer_model.dart';
import '../../../auth/domain/entities/farmer_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required DatabaseHelper databaseHelper,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Connectivity? connectivity,
    Logger? logger,
  })  : _databaseHelper = databaseHelper,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _connectivity = connectivity ?? Connectivity(),
        _logger = logger ?? Logger();

  final DatabaseHelper _databaseHelper;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Connectivity _connectivity;
  final Logger _logger;

  @override
  Future<FarmerEntity> getProfile(String farmerId) async {
    FarmerModel? localModel;
    try {
      final Map<String, dynamic>? local = await _databaseHelper.getFarmerById(farmerId);
      if (local != null) {
        localModel = FarmerModel.fromJson(local);
      }

      final bool online = await _isOnline();
      if (online) {
        try {
          final DocumentSnapshot<Map<String, dynamic>> doc =
              await _firestore.collection('farmers').doc(farmerId).get();
          if (doc.exists) {
            final FarmerModel remoteModel = FarmerModel.fromFirestore(doc);
            await _databaseHelper.insertFarmer(
              remoteModel.toJson(
                updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
              )
                ..[DatabaseConstants.columnSynced] = 1,
            );
            return remoteModel;
          }
        } on FirebaseException catch (error, stackTrace) {
          _logger.e('Failed to refresh profile from Firestore', error: error, stackTrace: stackTrace);
        }
      }

      if (localModel != null) {
        return localModel;
      }

      throw StateError('Profile not found for farmerId: $farmerId');
    } catch (error, stackTrace) {
      _logger.e('getProfile failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(FarmerEntity farmer) async {
    final int nowMillis = DateTime.now().millisecondsSinceEpoch;
    final FarmerModel localModel = FarmerModel.fromEntity(farmer, synced: false);

    try {
      await _databaseHelper.insertFarmer(localModel.toJson(updatedAtMillis: nowMillis));

      final bool online = await _isOnline();
      if (!online) {
        await _databaseHelper.addToSyncQueue(
          DatabaseConstants.farmersTable,
          farmer.id,
          'update',
          <String, dynamic>{
            DatabaseConstants.columnId: farmer.id,
            DatabaseConstants.columnPayload: localModel.toFirestore(),
          },
        );
        return;
      }

      try {
        await _firestore
            .collection('farmers')
            .doc(farmer.id)
            .set(localModel.toFirestore(), SetOptions(merge: true));
        await _databaseHelper.markFarmerSynced(farmer.id);
      } on FirebaseException catch (error, stackTrace) {
        _logger.e('Failed to sync profile update', error: error, stackTrace: stackTrace);
        await _databaseHelper.addToSyncQueue(
          DatabaseConstants.farmersTable,
          farmer.id,
          'update',
          <String, dynamic>{
            DatabaseConstants.columnId: farmer.id,
            DatabaseConstants.columnPayload: localModel.toFirestore(),
          },
        );
      }
    } catch (error, stackTrace) {
      _logger.e('updateProfile failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> updateProfileImage(String farmerId, File imageFile) async {
    try {
      final Uint8List compressedBytes = await _compressProfileImage(imageFile);
      final Reference ref = _storage.ref().child('farmers/$farmerId/profile.jpg');
      await ref.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final String downloadUrl = await ref.getDownloadURL();

      final Map<String, dynamic>? local = await _databaseHelper.getFarmerById(farmerId);
      if (local != null) {
        final Map<String, dynamic> updated = Map<String, dynamic>.from(local)
          ..[DatabaseConstants.columnProfileImageUrl] = downloadUrl
          ..[DatabaseConstants.columnUpdatedAt] = DateTime.now().millisecondsSinceEpoch
          ..[DatabaseConstants.columnSynced] = 0;
        await _databaseHelper.insertFarmer(updated);
      }

      final bool online = await _isOnline();
      if (online) {
        await _firestore.collection('farmers').doc(farmerId).set(
          <String, dynamic>{'profileImageUrl': downloadUrl},
          SetOptions(merge: true),
        );
        await _databaseHelper.markFarmerSynced(farmerId);
      }

      return downloadUrl;
    } catch (error, stackTrace) {
      _logger.e('updateProfileImage failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> _isOnline() async {
    final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
    return connectivityResults.any((ConnectivityResult value) => value != ConnectivityResult.none);
  }

  Future<Uint8List> _compressProfileImage(File imageFile) async {
    final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      '${imageFile.parent.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      quality: 70,
      minWidth: 720,
      minHeight: 720,
      format: CompressFormat.jpeg,
    );

    final File source = compressed == null ? imageFile : File(compressed.path);
    return source.readAsBytes();
  }
}

// lib/features/crops/data/datasources/firestore_crop_datasource.dart
// Firestore datasource for remote crop read/write operations.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:logger/logger.dart';

import '../models/crop_model.dart';

class FirestoreCropDataSource {
  FirestoreCropDataSource({FirebaseFirestore? firestore, Logger? logger})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _logger = logger ?? Logger();

  final FirebaseFirestore _firestore;
  final Logger _logger;

  Future<void> saveCrop(CropModel crop) async {
    try {
      await _firestore.collection('crops').doc(crop.id).set(crop.toFirestore());
    } on FirebaseException catch (error, stackTrace) {
      _logger.e(
        'Firestore saveCrop failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected saveCrop failure',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<CropModel>> getCrops(String farmerId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> query = await _firestore
          .collection('crops')
          .where('farmerId', isEqualTo: farmerId)
          .get();
      return query.docs.map(CropModel.fromFirestore).toList();
    } on FirebaseException catch (error, stackTrace) {
      _logger.e(
        'Firestore getCrops failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected getCrops failure',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteCrop(String id) async {
    try {
      await _firestore.collection('crops').doc(id).delete();
    } on FirebaseException catch (error, stackTrace) {
      _logger.e(
        'Firestore deleteCrop failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected deleteCrop failure',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

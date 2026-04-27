// lib/features/farms/data/repositories/farm_repository_impl.dart
/// Offline-first repository for farm details and GPS location tagging.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

import '../../../../shared/database/database_constants.dart';
import '../../../../shared/database/database_helper.dart';
import '../../domain/entities/farm_entity.dart';
import '../../domain/repositories/farm_repository.dart';

class FarmRepositoryImpl implements FarmRepository {
  FarmRepositoryImpl({
    required DatabaseHelper databaseHelper,
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
    Logger? logger,
  })  : _databaseHelper = databaseHelper,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? Connectivity(),
        _logger = logger ?? Logger();

  final DatabaseHelper _databaseHelper;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  final Logger _logger;

  @override
  Future<void> saveFarm(FarmEntity farm) async {
    try {
      await _databaseHelper.insertFarm(_toDbMap(farm, synced: false));

      final bool online = await _isOnline();
      if (!online) {
        await _enqueueFarmSync(farm.id, 'upsert', _toFirestoreMap(farm));
        return;
      }

      try {
        await _firestore.collection('farms').doc(farm.id).set(_toFirestoreMap(farm), SetOptions(merge: true));
        await _databaseHelper.markFarmSynced(farm.id);
      } on FirebaseException catch (error, stackTrace) {
        _logger.e('saveFarm cloud sync failed', error: error, stackTrace: stackTrace);
        await _enqueueFarmSync(farm.id, 'upsert', _toFirestoreMap(farm));
      } catch (error, stackTrace) {
        _logger.e('saveFarm unexpected cloud sync failure', error: error, stackTrace: stackTrace);
        await _enqueueFarmSync(farm.id, 'upsert', _toFirestoreMap(farm));
      }
    } catch (error, stackTrace) {
      _logger.e('saveFarm failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<FarmEntity?> getFarm(String farmerId) async {
    try {
      final Map<String, dynamic>? localRow = await _databaseHelper.getFarmByFarmerId(farmerId);
      final FarmEntity? localFarm = localRow == null ? null : _fromDbMap(localRow);
      final bool localIsUnsynced = (localRow?[DatabaseConstants.columnSynced] as int? ?? 0) == 0;

      if (localFarm != null && localIsUnsynced) {
        return localFarm;
      }

      final bool online = await _isOnline();
      if (online) {
        try {
          final QuerySnapshot<Map<String, dynamic>> query = await _firestore
              .collection('farms')
              .where('farmerId', isEqualTo: farmerId)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            final DocumentSnapshot<Map<String, dynamic>> doc = query.docs.first;
            final FarmEntity remoteFarm = _fromFirestoreDoc(doc);
            await _databaseHelper.insertFarm(
              _toDbMap(remoteFarm, synced: true),
            );
            return remoteFarm;
          }
        } on FirebaseException catch (error, stackTrace) {
          _logger.e('getFarm cloud refresh failed', error: error, stackTrace: stackTrace);
        } catch (error, stackTrace) {
          _logger.e('getFarm unexpected cloud refresh failure', error: error, stackTrace: stackTrace);
        }
      }

      return localFarm;
    } catch (error, stackTrace) {
      _logger.e('getFarm failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateFarmLocation(String farmId, double lat, double lng, String? address) async {
    final int now = DateTime.now().millisecondsSinceEpoch;

    try {
      await _databaseHelper.updateFarm(
        farmId,
        <String, dynamic>{
          DatabaseConstants.columnLatitude: lat,
          DatabaseConstants.columnLongitude: lng,
          DatabaseConstants.columnAddress: address,
          DatabaseConstants.columnUpdatedAt: now,
          DatabaseConstants.columnSynced: 0,
        },
      );

      final bool online = await _isOnline();
      if (!online) {
        await _enqueueFarmSync(
          farmId,
          'update_location',
          <String, dynamic>{
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'updatedAt': Timestamp.fromMillisecondsSinceEpoch(now),
          },
        );
        return;
      }

      try {
        await _firestore.collection('farms').doc(farmId).set(
          <String, dynamic>{
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'updatedAt': Timestamp.fromMillisecondsSinceEpoch(now),
          },
          SetOptions(merge: true),
        );
        await _databaseHelper.markFarmSynced(farmId);
      } on FirebaseException catch (error, stackTrace) {
        _logger.e('updateFarmLocation cloud sync failed', error: error, stackTrace: stackTrace);
        await _enqueueFarmSync(
          farmId,
          'update_location',
          <String, dynamic>{
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'updatedAt': Timestamp.fromMillisecondsSinceEpoch(now),
          },
        );
      } catch (error, stackTrace) {
        _logger.e('updateFarmLocation unexpected cloud sync failure', error: error, stackTrace: stackTrace);
        await _enqueueFarmSync(
          farmId,
          'update_location',
          <String, dynamic>{
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'updatedAt': Timestamp.fromMillisecondsSinceEpoch(now),
          },
        );
      }
    } catch (error, stackTrace) {
      _logger.e('updateFarmLocation failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> _toDbMap(FarmEntity farm, {required bool synced}) {
    return <String, dynamic>{
      DatabaseConstants.columnId: farm.id,
      DatabaseConstants.columnFarmerId: farm.farmerId,
      DatabaseConstants.columnName: farm.name,
      DatabaseConstants.columnLatitude: farm.latitude,
      DatabaseConstants.columnLongitude: farm.longitude,
      DatabaseConstants.columnSizeHa: farm.sizeHa,
      DatabaseConstants.columnAddress: farm.address,
      DatabaseConstants.columnUpdatedAt: farm.updatedAt.millisecondsSinceEpoch,
      DatabaseConstants.columnSynced: synced ? 1 : 0,
    };
  }

  Map<String, dynamic> _toFirestoreMap(FarmEntity farm) {
    return <String, dynamic>{
      'farmerId': farm.farmerId,
      'name': farm.name,
      'latitude': farm.latitude,
      'longitude': farm.longitude,
      'sizeHa': farm.sizeHa,
      'address': farm.address,
      'updatedAt': Timestamp.fromDate(farm.updatedAt),
    };
  }

  FarmEntity _fromDbMap(Map<String, dynamic> json) {
    return FarmEntity(
      id: json[DatabaseConstants.columnId] as String,
      farmerId: json[DatabaseConstants.columnFarmerId] as String,
      name: json[DatabaseConstants.columnName] as String,
      latitude: (json[DatabaseConstants.columnLatitude] as num?)?.toDouble(),
      longitude: (json[DatabaseConstants.columnLongitude] as num?)?.toDouble(),
      sizeHa: (json[DatabaseConstants.columnSizeHa] as num?)?.toDouble(),
      address: json[DatabaseConstants.columnAddress] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json[DatabaseConstants.columnUpdatedAt] as num).toInt(),
      ),
    );
  }

  FarmEntity _fromFirestoreDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final Timestamp updatedAtTs = data['updatedAt'] as Timestamp? ?? Timestamp.now();

    return FarmEntity(
      id: doc.id,
      farmerId: (data['farmerId'] as String?) ?? '',
      name: (data['name'] as String?) ?? 'My Farm',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      sizeHa: (data['sizeHa'] as num?)?.toDouble(),
      address: data['address'] as String?,
      updatedAt: updatedAtTs.toDate(),
    );
  }

  Future<void> _enqueueFarmSync(String farmId, String operation, Map<String, dynamic> payload) async {
    final int createdAt = DateTime.now().millisecondsSinceEpoch;
    await _databaseHelper.addToSyncQueue(
      DatabaseConstants.farmsTable,
      farmId,
      operation,
      <String, dynamic>{
        DatabaseConstants.columnId: 'farm_${farmId}_$createdAt',
        DatabaseConstants.columnCreatedAt: createdAt,
        DatabaseConstants.columnPayload: payload,
      },
    );
  }

  Future<bool> _isOnline() async {
    final List<ConnectivityResult> statuses = await _connectivity.checkConnectivity();
    return statuses.any((ConnectivityResult value) => value != ConnectivityResult.none);
  }
}

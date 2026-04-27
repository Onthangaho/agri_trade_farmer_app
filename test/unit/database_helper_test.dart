// test/unit/database_helper_test.dart
/// Unit tests for the SQLite database helper and schema.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:agri_trade_farmer_app/shared/database/database_constants.dart';
import 'package:agri_trade_farmer_app/shared/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper databaseHelper;

  setUp(() async {
    databaseHelper = DatabaseHelper();
    await databaseHelper.close();
    databaseHelper.setDatabasePathForTesting(inMemoryDatabasePath);
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  test('Database creates all 4 tables on first launch', () async {
    final dynamic db = await databaseHelper.database;
    final List<Map<String, Object?>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );

    final Set<String> tableNames = tables
        .map((Map<String, Object?> row) => row['name'] as String)
        .toSet();

    expect(tableNames.contains(DatabaseConstants.farmersTable), isTrue);
    expect(tableNames.contains(DatabaseConstants.cropsTable), isTrue);
    expect(tableNames.contains(DatabaseConstants.farmsTable), isTrue);
    expect(tableNames.contains(DatabaseConstants.syncQueueTable), isTrue);
  });

  test('Can insert a crop and retrieve it by farmerId', () async {
    await databaseHelper.insertCrop(<String, dynamic>{
      DatabaseConstants.columnId: 'crop-1',
      DatabaseConstants.columnFarmerId: 'farmer-1',
      DatabaseConstants.columnName: 'Tomatoes',
      DatabaseConstants.columnQuantity: 25.0,
      DatabaseConstants.columnUnit: 'kg',
      DatabaseConstants.columnPricePerUnit: 12.5,
      DatabaseConstants.columnImageUrl: null,
      DatabaseConstants.columnLocalImagePath: null,
      DatabaseConstants.columnDescription: 'Fresh tomatoes',
      DatabaseConstants.columnListedAt: 1710000000000,
      DatabaseConstants.columnExpiresAt: null,
      DatabaseConstants.columnStatus: 'active',
      DatabaseConstants.columnUpdatedAt: 1710000000000,
      DatabaseConstants.columnSynced: 0,
    });

    final List<Map<String, dynamic>> crops = await databaseHelper.getCropsByFarmer('farmer-1');

    expect(crops, hasLength(1));
    expect(crops.first[DatabaseConstants.columnName], 'Tomatoes');
    expect(crops.first[DatabaseConstants.columnFarmerId], 'farmer-1');
  });

  test('markCropSynced sets synced=1 correctly', () async {
    await databaseHelper.insertCrop(<String, dynamic>{
      DatabaseConstants.columnId: 'crop-2',
      DatabaseConstants.columnFarmerId: 'farmer-2',
      DatabaseConstants.columnName: 'Maize',
      DatabaseConstants.columnQuantity: 10.0,
      DatabaseConstants.columnUnit: 'bags',
      DatabaseConstants.columnPricePerUnit: 100.0,
      DatabaseConstants.columnImageUrl: null,
      DatabaseConstants.columnLocalImagePath: null,
      DatabaseConstants.columnDescription: null,
      DatabaseConstants.columnListedAt: 1710000001000,
      DatabaseConstants.columnExpiresAt: null,
      DatabaseConstants.columnStatus: 'active',
      DatabaseConstants.columnUpdatedAt: 1710000001000,
      DatabaseConstants.columnSynced: 0,
    });

    await databaseHelper.markCropSynced('crop-2');
    final Map<String, dynamic>? crop = await databaseHelper.getCropById('crop-2');

    expect(crop, isNotNull);
    expect(crop![DatabaseConstants.columnSynced], 1);
  });

  test('getUnsyncedCrops returns only rows where synced=0', () async {
    await databaseHelper.insertCrop(<String, dynamic>{
      DatabaseConstants.columnId: 'crop-3',
      DatabaseConstants.columnFarmerId: 'farmer-3',
      DatabaseConstants.columnName: 'Onions',
      DatabaseConstants.columnQuantity: 40.0,
      DatabaseConstants.columnUnit: 'kg',
      DatabaseConstants.columnPricePerUnit: 8.0,
      DatabaseConstants.columnImageUrl: null,
      DatabaseConstants.columnLocalImagePath: null,
      DatabaseConstants.columnDescription: null,
      DatabaseConstants.columnListedAt: 1710000002000,
      DatabaseConstants.columnExpiresAt: null,
      DatabaseConstants.columnStatus: 'active',
      DatabaseConstants.columnUpdatedAt: 1710000002000,
      DatabaseConstants.columnSynced: 0,
    });

    await databaseHelper.insertCrop(<String, dynamic>{
      DatabaseConstants.columnId: 'crop-4',
      DatabaseConstants.columnFarmerId: 'farmer-3',
      DatabaseConstants.columnName: 'Beans',
      DatabaseConstants.columnQuantity: 20.0,
      DatabaseConstants.columnUnit: 'kg',
      DatabaseConstants.columnPricePerUnit: 15.0,
      DatabaseConstants.columnImageUrl: null,
      DatabaseConstants.columnLocalImagePath: null,
      DatabaseConstants.columnDescription: null,
      DatabaseConstants.columnListedAt: 1710000003000,
      DatabaseConstants.columnExpiresAt: null,
      DatabaseConstants.columnStatus: 'active',
      DatabaseConstants.columnUpdatedAt: 1710000003000,
      DatabaseConstants.columnSynced: 1,
    });

    final List<Map<String, dynamic>> unsyncedCrops = await databaseHelper.getUnsyncedCrops();

    expect(unsyncedCrops, hasLength(1));
    expect(unsyncedCrops.first[DatabaseConstants.columnId], 'crop-3');
    expect(unsyncedCrops.first[DatabaseConstants.columnSynced], 0);
  });
}
// lib/shared/database/database_constants.dart
/// SQLite table and column names used by the local database helper.

class DatabaseConstants {
  DatabaseConstants._();

  static const String cropsTable = 'crops';
  static const String farmersTable = 'farmers';
  static const String farmsTable = 'farms';
  static const String syncQueueTable = 'sync_queue';

  static const String columnId = 'id';
  static const String columnFarmerId = 'farmer_id';
  static const String columnName = 'name';
  static const String columnQuantity = 'quantity';
  static const String columnUnit = 'unit';
  static const String columnPricePerUnit = 'price_per_unit';
  static const String columnImageUrl = 'image_url';
  static const String columnLocalImagePath = 'local_image_path';
  static const String columnDescription = 'description';
  static const String columnListedAt = 'listed_at';
  static const String columnExpiresAt = 'expires_at';
  static const String columnStatus = 'status';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnSynced = 'synced';

  static const String columnPhone = 'phone';
  static const String columnEmail = 'email';
  static const String columnBio = 'bio';
  static const String columnProfileImageUrl = 'profile_image_url';
  static const String columnCreatedAt = 'created_at';

  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnSizeHa = 'size_ha';
  static const String columnAddress = 'address';

  static const String columnTableName = 'table_name';
  static const String columnRecordId = 'record_id';
  static const String columnOperation = 'operation';
  static const String columnPayload = 'payload';
  static const String columnRetryCount = 'retry_count';
}

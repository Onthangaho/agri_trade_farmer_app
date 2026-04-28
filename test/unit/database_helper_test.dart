// test/unit/database_helper_test.dart
/// Unit tests for the SQLite database helper and schema.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'package:agri_trade_farmer_app/shared/database/database_constants.dart';
import 'package:agri_trade_farmer_app/shared/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper databaseHelper;
  late FakeDatabase fakeDatabase;

  setUp(() async {
    databaseHelper = DatabaseHelper();
    await databaseHelper.close();
    fakeDatabase = FakeDatabase();
    databaseHelper.setDatabaseForTesting(fakeDatabase);
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  test('Database creates all 4 tables on first launch', () async {
    final Database db = await databaseHelper.database;
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

    final List<Map<String, dynamic>> crops = await databaseHelper
        .getCropsByFarmer('farmer-1');

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
    final Map<String, dynamic>? crop = await databaseHelper.getCropById(
      'crop-2',
    );

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

    final List<Map<String, dynamic>> unsyncedCrops = await databaseHelper
        .getUnsyncedCrops();

    expect(unsyncedCrops, hasLength(1));
    expect(unsyncedCrops.first[DatabaseConstants.columnId], 'crop-3');
    expect(unsyncedCrops.first[DatabaseConstants.columnSynced], 0);
  });
}

class FakeDatabase implements Database, Transaction {
  FakeDatabase()
    : _tables = <String>{
        DatabaseConstants.farmersTable,
        DatabaseConstants.cropsTable,
        DatabaseConstants.farmsTable,
        DatabaseConstants.syncQueueTable,
      },
      _rows = <String, List<Map<String, Object?>>>{
        DatabaseConstants.farmersTable: <Map<String, Object?>>[],
        DatabaseConstants.cropsTable: <Map<String, Object?>>[],
        DatabaseConstants.farmsTable: <Map<String, Object?>>[],
        DatabaseConstants.syncQueueTable: <Map<String, Object?>>[],
      };

  final Set<String> _tables;
  final Map<String, List<Map<String, Object?>>> _rows;
  bool _isOpen = true;

  @override
  String get path => ':memory:';

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) {
    return action(this);
  }

  @override
  Future<T> readTransaction<T>(Future<T> Function(Transaction txn) action) {
    return action(this);
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    final RegExp createTablePattern = RegExp(
      r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([A-Za-z0-9_]+)',
      caseSensitive: false,
    );
    final Match? match = createTablePattern.firstMatch(sql);
    if (match != null) {
      final String tableName = match.group(1)!;
      _tables.add(tableName);
      _rows.putIfAbsent(tableName, () => <Map<String, Object?>>[]);
    }
  }

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) {
    throw UnimplementedError('rawInsert is not used by this test fake');
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    _ensureTable(table);
    final List<Map<String, Object?>> rows = _rows[table]!;
    final Map<String, Object?> row = Map<String, Object?>.from(values);
    final Object? idValue = row[DatabaseConstants.columnId];
    final int existingIndex = rows.indexWhere(
      (Map<String, Object?> current) =>
          current[DatabaseConstants.columnId] == idValue,
    );
    if (existingIndex >= 0) {
      rows[existingIndex] = row;
    } else {
      rows.add(row);
    }
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    _ensureTable(table);
    List<Map<String, Object?>> results = _rows[table]!.map(_cloneRow).toList();

    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      final String column = _extractColumn(where);
      final Object? expectedValue = whereArgs.first;
      results = results
          .where((Map<String, Object?> row) => row[column] == expectedValue)
          .map(_cloneRow)
          .toList();
    }

    if (orderBy != null) {
      final bool descending = orderBy.toUpperCase().contains(' DESC');
      final String orderColumn = orderBy.split(RegExp(r'\s+')).first;
      results.sort((Map<String, Object?> a, Map<String, Object?> b) {
        final Comparable<Object?> left = _asComparable(a[orderColumn]);
        final Comparable<Object?> right = _asComparable(b[orderColumn]);
        final int comparison = left.compareTo(right);
        return descending ? -comparison : comparison;
      });
    }

    if (offset != null && offset > 0) {
      if (offset < results.length) {
        results = results.sublist(offset);
      } else {
        results = <Map<String, Object?>>[];
      }
    }

    if (limit != null && limit < results.length) {
      results = results.sublist(0, limit);
    }

    if (columns != null && columns.isNotEmpty) {
      return results
          .map(
            (Map<String, Object?> row) => <String, Object?>{
              for (final String column in columns) column: row[column],
            },
          )
          .toList();
    }

    return results;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final String normalized = sql.trim().toLowerCase();
    if (normalized == "select name from sqlite_master where type='table'") {
      return _tables
          .map((String tableName) => <String, Object?>{'name': tableName})
          .toList();
    }
    throw UnimplementedError(
      'rawQuery is only implemented for sqlite_master in this fake',
    );
  }

  @override
  Future<QueryCursor> rawQueryCursor(
    String sql,
    List<Object?>? arguments, {
    int? bufferSize,
  }) {
    throw UnimplementedError('rawQueryCursor is not used by these tests');
  }

  @override
  Future<QueryCursor> queryCursor(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    int? bufferSize,
  }) {
    throw UnimplementedError('queryCursor is not used by these tests');
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    final RegExp incrementPattern = RegExp(
      r'UPDATE\s+([A-Za-z0-9_]+)\s+SET\s+([A-Za-z0-9_]+)\s*=\s*\2\s*\+\s*1\s+WHERE\s+([A-Za-z0-9_]+)\s*=\s*\?',
      caseSensitive: false,
    );
    final Match? match = incrementPattern.firstMatch(sql);
    if (match != null) {
      final String table = match.group(1)!;
      final String column = match.group(2)!;
      final String whereColumn = match.group(3)!;
      final Object? whereValue = arguments != null && arguments.isNotEmpty
          ? arguments.first
          : null;
      final List<Map<String, Object?>> rows =
          _rows[table] ?? <Map<String, Object?>>[];
      int affected = 0;
      for (final Map<String, Object?> row in rows) {
        if (row[whereColumn] == whereValue) {
          final num currentValue = (row[column] as num?) ?? 0;
          row[column] = currentValue + 1;
          affected++;
        }
      }
      return affected;
    }
    throw UnimplementedError(
      'rawUpdate is only implemented for retry count increments in this fake',
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    _ensureTable(table);
    final List<Map<String, Object?>> rows = _rows[table]!;
    int affected = 0;

    for (final Map<String, Object?> row in rows) {
      if (_matchesWhere(row, where, whereArgs)) {
        row.addAll(values);
        affected++;
      }
    }

    return affected;
  }

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) {
    throw UnimplementedError('rawDelete is not used by these tests');
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    _ensureTable(table);
    final List<Map<String, Object?>> rows = _rows[table]!;
    final int originalLength = rows.length;
    rows.removeWhere(
      (Map<String, Object?> row) => _matchesWhere(row, where, whereArgs),
    );
    return originalLength - rows.length;
  }

  @override
  Batch batch() {
    throw UnimplementedError('batch is not used by these tests');
  }

  @override
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]) {
    throw UnimplementedError('devInvokeMethod is not used by these tests');
  }

  @override
  Future<T> devInvokeSqlMethod<T>(
    String method,
    String sql, [
    List<Object?>? arguments,
  ]) {
    throw UnimplementedError('devInvokeSqlMethod is not used by these tests');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void _ensureTable(String table) {
    _tables.add(table);
    _rows.putIfAbsent(table, () => <Map<String, Object?>>[]);
  }

  bool _matchesWhere(
    Map<String, Object?> row,
    String? where,
    List<Object?>? whereArgs,
  ) {
    if (where == null) {
      return true;
    }
    if (whereArgs == null || whereArgs.isEmpty) {
      return false;
    }
    final String column = _extractColumn(where);
    return row[column] == whereArgs.first;
  }

  String _extractColumn(String whereClause) {
    return whereClause.split('=').first.trim();
  }

  Map<String, Object?> _cloneRow(Map<String, Object?> row) {
    return Map<String, Object?>.from(row);
  }

  Comparable<Object?> _asComparable(Object? value) {
    if (value is Comparable<Object?>) {
      return value;
    }
    if (value is num) {
      return value;
    }
    return value?.toString() ?? '';
  }
}

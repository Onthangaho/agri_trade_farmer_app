import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:agri_trade_farmer_app/features/crops/domain/entities/crop_entity.dart';
import 'package:agri_trade_farmer_app/features/crops/domain/repositories/crop_repository.dart';
import 'package:agri_trade_farmer_app/features/crops/domain/use_cases/delete_crop_use_case.dart';
import 'package:agri_trade_farmer_app/features/crops/domain/use_cases/get_crops_use_case.dart';
import 'package:agri_trade_farmer_app/features/crops/domain/use_cases/save_crop_use_case.dart';
import 'package:agri_trade_farmer_app/features/crops/domain/use_cases/update_crop_use_case.dart';
import 'package:agri_trade_farmer_app/features/crops/presentation/providers/crop_provider.dart';

class _FakeRepo implements CropRepository {
  final List<CropEntity> _store = <CropEntity>[];

  @override
  Future<void> deleteCrop(String id) async {
    _store.removeWhere((e) => e.id == id);
  }

  @override
  Future<CropEntity?> getCropById(String id) async {
    try {
      return _store.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CropEntity>> getCrops(String farmerId) async {
    return _store.where((e) => e.farmerId == farmerId).toList(growable: false);
  }

  @override
  Future<void> saveCrop(CropEntity crop, {File? imageFile}) async {
    _store.removeWhere((e) => e.id == crop.id);
    _store.add(crop);
  }

  @override
  Future<void> updateCrop(CropEntity crop) async {
    final int idx = _store.indexWhere((e) => e.id == crop.id);
    if (idx >= 0) {
      _store[idx] = crop;
    } else {
      _store.add(crop);
    }
  }

  @override
  Future<void> syncPendingCrops() async {
    // No-op for tests
  }
}

void main() {
  late _FakeRepo repo;
  late CropProvider provider;

  setUp(() {
    repo = _FakeRepo();
    provider = CropProvider(
      getCrops: GetCropsUseCase(repository: repo),
      saveCrop: SaveCropUseCase(repository: repo),
      updateCrop: UpdateCropUseCase(repository: repo),
      deleteCrop: DeleteCropUseCase(repository: repo),
      repository: repo,
    );
  });

  test('loadCrops loads crops for a farmer', () async {
    final CropEntity c1 = CropEntity(
      id: 'c1',
      farmerId: 'f1',
      name: 'Maize',
      quantity: 10,
      unit: 'kg',
      pricePerUnit: 50,
      listedAt: DateTime.now(),
      status: 'available',
    );
    await repo.saveCrop(c1);

    expect(provider.isLoading, isFalse);
    final future = provider.loadCrops('f1');
    expect(provider.isLoading, isTrue);
    await future;
    expect(provider.isLoading, isFalse);
    expect(provider.crops, contains(c1));
  });

  test('saveCrop adds a crop locally', () async {
    final CropEntity c2 = CropEntity(
      id: 'c2',
      farmerId: 'f2',
      name: 'Beans',
      quantity: 5,
      unit: 'kg',
      pricePerUnit: 30,
      listedAt: DateTime.now(),
      status: 'available',
    );

    final future = provider.saveCrop(c2);
    expect(provider.isSaving, isTrue);
    await future;
    expect(provider.isSaving, isFalse);
    expect(provider.crops, contains(c2));
  });

  test('updateCrop replaces existing crop', () async {
    final CropEntity c3 = CropEntity(
      id: 'c3',
      farmerId: 'f3',
      name: 'Rice',
      quantity: 20,
      unit: 'kg',
      pricePerUnit: 70,
      listedAt: DateTime.now(),
      status: 'available',
    );
    await repo.saveCrop(c3);
    await provider.loadCrops('f3');

    final CropEntity updated = c3.copyWith(pricePerUnit: 80);
    await provider.updateCrop(updated);
    expect(provider.crops.firstWhere((e) => e.id == 'c3').pricePerUnit, 80);
  });

  test('deleteCrop removes crop and returns true', () async {
    final CropEntity c4 = CropEntity(
      id: 'c4',
      farmerId: 'f4',
      name: 'Wheat',
      quantity: 15,
      unit: 'kg',
      pricePerUnit: 60,
      listedAt: DateTime.now(),
      status: 'available',
    );
    await repo.saveCrop(c4);
    await provider.loadCrops('f4');

    final bool deleted = await provider.deleteCrop('c4');
    expect(deleted, isTrue);
    expect(provider.crops.any((e) => e.id == 'c4'), isFalse);
  });
}

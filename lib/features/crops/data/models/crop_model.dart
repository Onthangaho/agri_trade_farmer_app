// lib/features/crops/data/models/crop_model.dart
// Data model for CropEntity serialization to SQLite and Firestore formats.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/database/database_constants.dart';
import '../../domain/entities/crop_entity.dart';

class CropModel extends CropEntity {
  const CropModel({
    required super.id,
    required super.farmerId,
    required super.name,
    required super.quantity,
    required super.unit,
    required super.pricePerUnit,
    required super.listedAt,
    required super.status,
    super.synced = false,
    super.imageUrl,
    super.localImagePath,
    super.description,
    super.expiresAt,
  });

  factory CropModel.fromEntity(CropEntity crop, {bool synced = false}) {
    return CropModel(
      id: crop.id,
      farmerId: crop.farmerId,
      name: crop.name,
      quantity: crop.quantity,
      unit: crop.unit,
      pricePerUnit: crop.pricePerUnit,
      imageUrl: crop.imageUrl,
      localImagePath: crop.localImagePath,
      description: crop.description,
      listedAt: crop.listedAt,
      expiresAt: crop.expiresAt,
      status: crop.status,
      synced: synced,
    );
  }

  factory CropModel.fromJson(Map<String, dynamic> json) {
    return CropModel(
      id: json[DatabaseConstants.columnId] as String,
      farmerId: json[DatabaseConstants.columnFarmerId] as String,
      name: json[DatabaseConstants.columnName] as String,
      quantity: (json[DatabaseConstants.columnQuantity] as num).toDouble(),
      unit: json[DatabaseConstants.columnUnit] as String,
      pricePerUnit: (json[DatabaseConstants.columnPricePerUnit] as num).toDouble(),
      imageUrl: json[DatabaseConstants.columnImageUrl] as String?,
      localImagePath: json[DatabaseConstants.columnLocalImagePath] as String?,
      description: json[DatabaseConstants.columnDescription] as String?,
      listedAt: DateTime.fromMillisecondsSinceEpoch(
        (json[DatabaseConstants.columnListedAt] as num).toInt(),
      ),
      expiresAt: (json[DatabaseConstants.columnExpiresAt] as num?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (json[DatabaseConstants.columnExpiresAt] as num).toInt(),
            ),
      status: (json[DatabaseConstants.columnStatus] as String?) ?? 'active',
      synced: ((json[DatabaseConstants.columnSynced] as num?) ?? 0).toInt() == 1,
    );
  }

  factory CropModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final Timestamp listedAtTs = data['listedAt'] as Timestamp? ?? Timestamp.now();
    final Timestamp? expiresAtTs = data['expiresAt'] as Timestamp?;

    return CropModel(
      id: doc.id,
      farmerId: (data['farmerId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      quantity: ((data['quantity'] as num?) ?? 0).toDouble(),
      unit: (data['unit'] as String?) ?? 'kg',
      pricePerUnit: ((data['pricePerUnit'] as num?) ?? 0).toDouble(),
      imageUrl: data['imageUrl'] as String?,
      localImagePath: null,
      description: data['description'] as String?,
      listedAt: listedAtTs.toDate(),
      expiresAt: expiresAtTs?.toDate(),
      status: (data['status'] as String?) ?? 'active',
      synced: true,
    );
  }

  Map<String, dynamic> toJson({required int updatedAtMillis}) {
    return <String, dynamic>{
      DatabaseConstants.columnId: id,
      DatabaseConstants.columnFarmerId: farmerId,
      DatabaseConstants.columnName: name,
      DatabaseConstants.columnQuantity: quantity,
      DatabaseConstants.columnUnit: unit,
      DatabaseConstants.columnPricePerUnit: pricePerUnit,
      DatabaseConstants.columnImageUrl: imageUrl,
      DatabaseConstants.columnLocalImagePath: localImagePath,
      DatabaseConstants.columnDescription: description,
      DatabaseConstants.columnListedAt: listedAt.millisecondsSinceEpoch,
      DatabaseConstants.columnExpiresAt: expiresAt?.millisecondsSinceEpoch,
      DatabaseConstants.columnStatus: status,
      DatabaseConstants.columnUpdatedAt: updatedAtMillis,
      DatabaseConstants.columnSynced: synced ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'farmerId': farmerId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'imageUrl': imageUrl,
      'description': description,
      'listedAt': Timestamp.fromDate(listedAt),
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
      'status': status,
    };
  }

  @override
  CropModel copyWith({
    String? id,
    String? farmerId,
    String? name,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    String? imageUrl,
    String? localImagePath,
    String? description,
    DateTime? listedAt,
    DateTime? expiresAt,
    String? status,
    bool? synced,
  }) {
    return CropModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      description: description ?? this.description,
      listedAt: listedAt ?? this.listedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      synced: synced ?? this.synced,
    );
  }
}

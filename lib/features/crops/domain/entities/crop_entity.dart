// lib/features/crops/domain/entities/crop_entity.dart
/// Domain entity representing a crop listing owned by a farmer.

import 'package:equatable/equatable.dart';

class CropEntity extends Equatable {
  const CropEntity({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.listedAt,
    required this.status,
    this.imageUrl,
    this.localImagePath,
    this.description,
    this.expiresAt,
  });

  final String id;
  final String farmerId;
  final String name;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final String? imageUrl;
  final String? localImagePath;
  final String? description;
  final DateTime listedAt;
  final DateTime? expiresAt;
  final String status;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!); // expiresAt null already checked

  CropEntity copyWith({
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
  }) {
    return CropEntity(
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
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        farmerId,
        name,
        quantity,
        unit,
        pricePerUnit,
        imageUrl,
        localImagePath,
        description,
        listedAt,
        expiresAt,
        status,
      ];
}

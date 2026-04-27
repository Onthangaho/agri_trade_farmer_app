// lib/features/farms/domain/entities/farm_entity.dart
/// Domain entity representing farmer's farm details and tagged GPS location.

import 'package:equatable/equatable.dart';

class FarmEntity extends Equatable {
  const FarmEntity({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.sizeHa,
    this.address,
  });

  final String id;
  final String farmerId;
  final String name;
  final double? latitude;
  final double? longitude;
  final double? sizeHa;
  final String? address;
  final DateTime updatedAt;

  bool get isTagged => latitude != null && longitude != null;

  FarmEntity copyWith({
    String? id,
    String? farmerId,
    String? name,
    double? latitude,
    double? longitude,
    double? sizeHa,
    String? address,
    DateTime? updatedAt,
  }) {
    return FarmEntity(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sizeHa: sizeHa ?? this.sizeHa,
      address: address ?? this.address,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        farmerId,
        name,
        latitude,
        longitude,
        sizeHa,
        address,
        updatedAt,
      ];
}

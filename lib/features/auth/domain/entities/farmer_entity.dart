// lib/features/auth/domain/entities/farmer_entity.dart
/// Domain entity representing a farmer profile across authentication and profile features.

import 'package:equatable/equatable.dart';

class FarmerEntity extends Equatable {
  const FarmerEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.phone,
    this.bio,
    this.profileImageUrl,
  });

  final String id;
  final String name;
  final String? phone;
  final String email;
  final String? bio;
  final String? profileImageUrl;
  final DateTime createdAt;

  FarmerEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? bio,
    String? profileImageUrl,
    DateTime? createdAt,
  }) {
    return FarmerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        phone,
        email,
        bio,
        profileImageUrl,
        createdAt,
      ];
}

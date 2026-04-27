// lib/features/auth/data/models/farmer_model.dart
/// Data model for FarmerEntity with SQLite and Firestore serialization helpers.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/database/database_constants.dart';
import '../../domain/entities/farmer_entity.dart';

class FarmerModel extends FarmerEntity {
  const FarmerModel({
    required super.id,
    required super.name,
    required super.email,
    required super.createdAt,
    super.phone,
    super.bio,
    super.profileImageUrl,
    this.synced = false,
  });

  final bool synced;

  factory FarmerModel.fromEntity(FarmerEntity entity, {bool synced = false}) {
    return FarmerModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      bio: entity.bio,
      profileImageUrl: entity.profileImageUrl,
      createdAt: entity.createdAt,
      synced: synced,
    );
  }

  factory FarmerModel.fromJson(Map<String, dynamic> json) {
    return FarmerModel(
      id: json[DatabaseConstants.columnId] as String,
      name: json[DatabaseConstants.columnName] as String,
      phone: json[DatabaseConstants.columnPhone] as String?,
      email: (json[DatabaseConstants.columnEmail] as String?) ?? '',
      bio: json[DatabaseConstants.columnBio] as String?,
      profileImageUrl: json[DatabaseConstants.columnProfileImageUrl] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json[DatabaseConstants.columnCreatedAt] as num).toInt(),
      ),
      synced: ((json[DatabaseConstants.columnSynced] as num?) ?? 0).toInt() == 1,
    );
  }

  factory FarmerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final Timestamp? createdAtStamp = data['createdAt'] as Timestamp?;
    return FarmerModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      phone: data['phone'] as String?,
      email: (data['email'] as String?) ?? '',
      bio: data['bio'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      createdAt: createdAtStamp?.toDate() ?? DateTime.now(),
      synced: true,
    );
  }

  Map<String, dynamic> toJson({required int updatedAtMillis}) {
    return <String, dynamic>{
      DatabaseConstants.columnId: id,
      DatabaseConstants.columnName: name,
      DatabaseConstants.columnPhone: phone,
      DatabaseConstants.columnEmail: email,
      DatabaseConstants.columnBio: bio,
      DatabaseConstants.columnProfileImageUrl: profileImageUrl,
      DatabaseConstants.columnCreatedAt: createdAt.millisecondsSinceEpoch,
      DatabaseConstants.columnUpdatedAt: updatedAtMillis,
      DatabaseConstants.columnSynced: synced ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'name': name,
      'phone': phone,
      'email': email,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FarmerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? bio,
    String? profileImageUrl,
    DateTime? createdAt,
    bool? synced,
  }) {
    return FarmerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }
}

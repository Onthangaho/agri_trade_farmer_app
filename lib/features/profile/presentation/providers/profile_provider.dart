// lib/features/profile/presentation/providers/profile_provider.dart
/// Profile provider that always resolves to a usable profile model.

import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../auth/domain/entities/farmer_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/use_cases/get_profile_use_case.dart';
import '../../domain/use_cases/update_profile_use_case.dart';

class ProfileProvider extends ChangeNotifier {
  static const int _maxFirestoreImageBytes = 520 * 1024;

  ProfileProvider({
    required GetProfileUseCase getProfile,
    required UpdateProfileUseCase updateProfile,
    required ProfileRepository profileRepository,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Logger? logger,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _logger = logger ?? Logger();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final Logger _logger;

  Map<String, dynamic>? _profileData;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isUpdating => _isSaving;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool get hasProfile => _profileData != null;
  String get displayName => (_profileData?['name'] as String?)?.trim().isNotEmpty == true
      ? (_profileData!['name'] as String).trim()
      : 'AgriTrade Farmer';
  String get email => (_profileData?['email'] as String?) ?? '';
  String get phone => (_profileData?['phone'] as String?) ?? '';
  String get bio => (_profileData?['bio'] as String?) ?? '';
  String get profileImageUrl => (_profileData?['profileImageUrl'] as String?) ?? '';

  FarmerEntity? get farmer {
    final Map<String, dynamic>? data = _profileData;
    if (data == null) {
      return null;
    }
    final String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return null;
    }
    final Timestamp createdAtTs =
        data['createdAt'] as Timestamp? ?? Timestamp.now();
    return FarmerEntity(
      id: uid,
      name: displayName,
      email: email,
      phone: phone.isEmpty ? null : phone,
      bio: bio.isEmpty ? null : bio,
      profileImageUrl: profileImageUrl.isEmpty ? null : profileImageUrl,
      createdAt: createdAtTs.toDate(),
    );
  }

  Future<void> loadProfile(String userId) async {
    if (userId.isEmpty) {
      _profileData = _fallbackProfileData();
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection('farmers').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        _profileData = doc.data()!;
      } else {
        _profileData = _fallbackProfileData();
        await _db.collection('farmers').doc(userId).set(_profileData!);
      }
    } on FirebaseException catch (error, stackTrace) {
      if (error.code != 'unavailable') {
        _logger.e('loadProfile Firebase failed', error: error, stackTrace: stackTrace);
      }
      _profileData = _fallbackProfileData();
      _errorMessage = error.code == 'unavailable'
          ? null
          : 'Could not refresh profile from cloud.';
    } catch (error, stackTrace) {
      _logger.e('loadProfile failed', error: error, stackTrace: stackTrace);
      _profileData = _fallbackProfileData();
      _errorMessage = 'Could not load profile right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String bio,
    String? profileImageUrl,
  }) async {
    if (userId.isEmpty) {
      _errorMessage = 'Please log in first.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name.trim().isEmpty ? 'AgriTrade Farmer' : name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'bio': bio.trim(),
      'profileImageUrl': profileImageUrl ?? this.profileImageUrl,
      'updatedAt': Timestamp.now(),
      'createdAt': (_profileData?['createdAt'] as Timestamp?) ?? Timestamp.now(),
    };

    try {
      await _db.collection('farmers').doc(userId).set(payload, SetOptions(merge: true));

      final User? user = _auth.currentUser;
      if (user != null && user.displayName != payload['name']) {
        await user.updateDisplayName(payload['name'] as String);
        await user.reload();
      }

      _profileData = <String, dynamic>{
        ...?_profileData,
        ...payload,
      };
      return true;
    } on FirebaseException catch (error, stackTrace) {
      _logger.e('saveProfile Firebase failed', error: error, stackTrace: stackTrace);
      _errorMessage = 'Failed to save profile. Please try again.';
      return false;
    } catch (error, stackTrace) {
      _logger.e('saveProfile failed', error: error, stackTrace: stackTrace);
      _errorMessage = 'Failed to save profile. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(FarmerEntity farmer) async {
    final bool success = await saveProfile(
      userId: farmer.id,
      name: farmer.name,
      email: farmer.email,
      phone: farmer.phone ?? '',
      bio: farmer.bio ?? '',
      profileImageUrl: farmer.profileImageUrl,
    );

    if (!success && _errorMessage == null) {
      _errorMessage = 'Could not update profile. Please try again.';
      notifyListeners();
    }
  }

  Future<void> updateImage(File imageFile) async {
    final String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      _errorMessage = 'Please log in first.';
      notifyListeners();
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final File? fileToSave = await _compressImageForFirestore(imageFile);
      if (fileToSave == null) {
        _errorMessage =
            'Image is too large for Firestore. Please pick a smaller photo.';
        return;
      }
      final List<int> bytes = await fileToSave.readAsBytes();
      final String dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      await _db.collection('farmers').doc(userId).set(
        <String, dynamic>{
          'profileImageUrl': dataUri,
          'updatedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );

      _profileData = <String, dynamic>{
        ...?_profileData,
        'profileImageUrl': dataUri,
      };
    } on FirebaseException catch (error, stackTrace) {
      _logger.e('updateImage Firebase failed', error: error, stackTrace: stackTrace);
      _errorMessage = 'Could not update profile image. Please try again.';
    } on SocketException {
      _errorMessage = 'No internet. Image will sync when connected.';
    } catch (error, stackTrace) {
      _logger.e('updateImage failed', error: error, stackTrace: stackTrace);
      _errorMessage = 'Could not update profile image. Please try again.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<File?> _compressImageForFirestore(File source) async {
    if (!source.existsSync()) {
      return null;
    }
    if (source.lengthSync() <= _maxFirestoreImageBytes) {
      return source;
    }

    final List<_CompressionPreset> presets = <_CompressionPreset>[
      const _CompressionPreset(quality: 65, minWidth: 720, minHeight: 720),
      const _CompressionPreset(quality: 55, minWidth: 640, minHeight: 640),
      const _CompressionPreset(quality: 45, minWidth: 560, minHeight: 560),
      const _CompressionPreset(quality: 35, minWidth: 480, minHeight: 480),
    ];

    File current = source;
    for (int i = 0; i < presets.length; i++) {
      final _CompressionPreset preset = presets[i];
      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        current.path,
        '${source.parent.path}/profile_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        quality: preset.quality,
        minWidth: preset.minWidth,
        minHeight: preset.minHeight,
        format: CompressFormat.jpeg,
      );
      if (compressed == null) {
        continue;
      }
      current = File(compressed.path);
      if (current.lengthSync() <= _maxFirestoreImageBytes) {
        return current;
      }
    }

    return null;
  }

  Map<String, dynamic> _fallbackProfileData() {
    final User? user = _auth.currentUser;
    return <String, dynamic>{
      'name': (user?.displayName ?? 'AgriTrade Farmer').trim(),
      'email': (user?.email ?? '').trim(),
      'phone': '',
      'bio': '',
      'profileImageUrl': '',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }
}

class _CompressionPreset {
  const _CompressionPreset({
    required this.quality,
    required this.minWidth,
    required this.minHeight,
  });

  final int quality;
  final int minWidth;
  final int minHeight;
}

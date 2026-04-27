// lib/features/marketplace/presentation/providers/marketplace_provider.dart
/// Marketplace provider for loading active listings and local search/filter state.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../crops/data/models/crop_model.dart';
import '../../../crops/domain/entities/crop_entity.dart';

class MarketplaceProvider extends ChangeNotifier {
  MarketplaceProvider({FirebaseFirestore? firestore, Logger? logger})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();

  final FirebaseFirestore _firestore;
  final Logger _logger;

  List<CropEntity> _listings = <CropEntity>[];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedUnit;

  List<CropEntity> get listings => List<CropEntity>.unmodifiable(_listings);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedUnit => _selectedUnit;

  List<CropEntity> get filteredListings {
    final String normalizedQuery = _searchQuery.trim().toLowerCase();
    final String? filter = _selectedUnit;

    final Set<String> knownTypes = <String>{'maize', 'tomatoes', 'potatoes', 'cabbage'};

    return _listings.where((CropEntity crop) {
      final String cropName = crop.name.toLowerCase();

      final bool matchesSearch = normalizedQuery.isEmpty || cropName.contains(normalizedQuery);

      bool matchesFilter = true;
      if (filter != null && filter.isNotEmpty && filter != 'All') {
        final String normalizedFilter = filter.toLowerCase();
        if (normalizedFilter == 'custom') {
          matchesFilter = !knownTypes.any((String type) => cropName.contains(type));
        } else {
          matchesFilter = cropName.contains(normalizedFilter);
        }
      }

      return matchesSearch && matchesFilter;
    }).toList(growable: false);
  }

  Future<void> loadListings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('crops')
          .where('status', isEqualTo: 'active')
          .orderBy('listedAt', descending: true)
          .get();

      _listings = snapshot.docs.map(CropModel.fromFirestore).toList(growable: false);
      _errorMessage = null;
    } catch (error, stackTrace) {
      _errorMessage = 'Could not load marketplace listings.';
      _logger.e('loadListings failed', error: error, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void filterByUnit(String? unit) {
    _selectedUnit = unit;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

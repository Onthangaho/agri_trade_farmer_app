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

  List<CropEntity> _allListings = <CropEntity>[];
  List<CropEntity> _filteredListings = <CropEntity>[];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedUnit;

  List<CropEntity> get listings => List<CropEntity>.unmodifiable(_allListings);
  List<CropEntity> get filteredListings => List<CropEntity>.unmodifiable(_filteredListings);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedUnit => _selectedUnit;

  void _applyFilters() {
    List<CropEntity> result = List<CropEntity>.from(_allListings);

    if (_searchQuery.trim().isNotEmpty) {
      final String query = _searchQuery.trim().toLowerCase();
      result = result
          .where(
            (CropEntity c) =>
                c.name.toLowerCase().contains(query) ||
                (c.description ?? '').toLowerCase().contains(query),
          )
          .toList(growable: false);
    }

    if (_selectedUnit != null && _selectedUnit != 'All') {
      final String selected = (_selectedUnit ?? '').toLowerCase();
      result = result
          .where((CropEntity c) => c.unit.toLowerCase() == selected)
          .toList(growable: false);
    }

    _filteredListings = result;
  }

  Future<void> loadListings({bool forceRefresh = false}) async {
    if (_hasLoaded && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('crops')
          .where('status', isEqualTo: 'active')
          .get();
      final List<CropEntity> remoteCrops = snapshot.docs
          .map(CropModel.fromFirestore)
          .toList(growable: false)
        ..sort((CropEntity a, CropEntity b) => b.listedAt.compareTo(a.listedAt));

      _allListings = remoteCrops;
      _hasLoaded = true;
      _applyFilters();
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
    _applyFilters();
    notifyListeners();
  }

  void filterByUnit(String? unit) {
    _selectedUnit = unit;
    _applyFilters();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _selectedUnit = null;
    _filteredListings = List<CropEntity>.from(_allListings);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

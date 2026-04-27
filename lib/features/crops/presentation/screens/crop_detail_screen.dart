// lib/features/crops/presentation/screens/crop_detail_screen.dart
/// Detailed crop listing screen with hero image and farmer contact section.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/crop_entity.dart';

class CropDetailScreen extends StatefulWidget {
  const CropDetailScreen({
    super.key,
    required this.crop,
  });

  final CropEntity crop;

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  late Future<_FarmerDetails> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _fetchFarmerDetails(widget.crop.farmerId);
  }

  Future<_FarmerDetails> _fetchFarmerDetails(String farmerId) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final DocumentSnapshot<Map<String, dynamic>> farmerDoc =
          await firestore.collection('farmers').doc(farmerId).get();
      final QuerySnapshot<Map<String, dynamic>> farmQuery = await firestore
          .collection('farms')
          .where('farmerId', isEqualTo: farmerId)
          .limit(1)
          .get();

      final Map<String, dynamic>? farmerData = farmerDoc.data();
      final Map<String, dynamic>? farmData = farmQuery.docs.isEmpty ? null : farmQuery.docs.first.data();

      return _FarmerDetails(
        name: (farmerData?['name'] as String?) ?? 'Unknown farmer',
        phone: farmerData?['phone'] as String?,
        location: farmData?['address'] as String?,
      );
    } catch (_) {
      return const _FarmerDetails(name: 'Unknown farmer', phone: null, location: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final CropEntity crop = widget.crop;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Stack(
        children: <Widget>[
          ListView(
            children: <Widget>[
              _buildHeroImage(crop),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      crop.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: AppColors.navyText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${crop.quantity.toStringAsFixed(crop.quantity % 1 == 0 ? 0 : 1)} ${crop.unit} • R ${crop.pricePerUnit.toStringAsFixed(2)} / ${crop.unit}',
                      style: const TextStyle(
                        fontFamily: 'Nunito Sans',
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<_FarmerDetails>(
                      future: _detailsFuture,
                      builder: (BuildContext context, AsyncSnapshot<_FarmerDetails> snapshot) {
                        final _FarmerDetails details = snapshot.data ??
                            const _FarmerDetails(name: 'Loading farmer...', phone: null, location: null);
                        return _buildFarmerCard(details);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      title: 'Quantity available',
                      value:
                          '${crop.quantity.toStringAsFixed(crop.quantity % 1 == 0 ? 0 : 1)} ${crop.unit}',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      title: 'Description',
                      value: (crop.description ?? '').isEmpty
                          ? 'No description provided.'
                          : crop.description!,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      title: 'Listing dates',
                      value:
                          'Listed: ${_formatDate(crop.listedAt)}\nExpiry: ${crop.expiresAt == null ? 'N/A' : _formatDate(crop.expiresAt!)}',
                    ),
                    const SizedBox(height: 18),
                    FutureBuilder<_FarmerDetails>(
                      future: _detailsFuture,
                      builder: (BuildContext context, AsyncSnapshot<_FarmerDetails> snapshot) {
                        final String phone = snapshot.data?.phone ?? 'Phone not available yet';
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentAmber,
                              foregroundColor: AppColors.navyText,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Contact: $phone')),
                              );
                            },
                            child: const Text('Contact Farmer'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 42,
            left: 16,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: AppColors.navyText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(CropEntity crop) {
    Widget child;

    if (crop.imageUrl != null && crop.imageUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: crop.imageUrl!,
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
      );
    } else if (crop.localImagePath != null && crop.localImagePath!.isNotEmpty) {
      child = Image.file(
        File(crop.localImagePath!),
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
      );
    } else {
      child = Container(
        height: 240,
        color: AppColors.surfaceMist,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 48, color: AppColors.mutedText),
        ),
      );
    }

    return Hero(tag: 'crop_${crop.id}', child: child);
  }

  Widget _buildFarmerCard(_FarmerDetails details) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            details.name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.navyText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            details.location ?? 'Farm location not tagged',
            style: const TextStyle(
              fontFamily: 'Nunito Sans',
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
              color: AppColors.navyText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito Sans',
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _FarmerDetails {
  const _FarmerDetails({
    required this.name,
    required this.phone,
    required this.location,
  });

  final String name;
  final String? phone;
  final String? location;
}

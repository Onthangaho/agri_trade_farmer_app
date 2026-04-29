import 'dart:io';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/crop_provider.dart';
import '../../domain/entities/crop_entity.dart';

class CropDetailScreen extends StatelessWidget {
  const CropDetailScreen({super.key, this.crop});

  final CropEntity? crop;

  @override
  Widget build(BuildContext context) {
    final Object? arg = ModalRoute.of(context)?.settings.arguments;
    final String? cropId = arg is String ? arg : null;
    final CropEntity? argCrop = arg is CropEntity ? arg : null;

    final CropEntity fallback = CropEntity(
      id: '',
      farmerId: '',
      name: 'Crop not found',
      quantity: 0,
      unit: 'kg',
      pricePerUnit: 0,
      listedAt: DateTime.now(),
      status: 'sold',
      description: 'This crop listing could not be loaded.',
    );

    final CropEntity selectedCrop = crop ??
        argCrop ??
        context.read<CropProvider>().crops.firstWhere(
              (CropEntity c) => c.id == cropId,
              orElse: () => fallback,
            );

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Stack(
        children: <Widget>[
          ListView(
            children: <Widget>[
              Hero(
                tag: 'crop_${selectedCrop.id}',
                child: _buildHeroImage(selectedCrop),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      selectedCrop.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: AppColors.navyText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreenLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'R ${selectedCrop.pricePerUnit.toStringAsFixed(2)} per ${selectedCrop.unit}',
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreenDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Quantity available: ${selectedCrop.quantity} ${selectedCrop.unit}',
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 15,
                        color: AppColors.navyText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _statusChip(selectedCrop),
                    const SizedBox(height: 16),
                    if ((selectedCrop.description ?? '').trim().isNotEmpty) ...<Widget>[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.navyText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        selectedCrop.description!,
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      'Listed: ${_formatDate(selectedCrop.listedAt)}',
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        color: AppColors.navyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expiry: ${selectedCrop.expiresAt == null ? 'N/A' : _formatDate(selectedCrop.expiresAt!)}',
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        color: AppColors.navyText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentAmber,
                          foregroundColor: AppColors.navyText,
                        ),
                        onPressed: () async {
                          await showDialog<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Contact Farmer'),
                                content: const Text(
                                  'Feature coming soon - contact via phone',
                                  style: TextStyle(fontFamily: 'NunitoSans'),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Contact Farmer'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: AppColors.navyText),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(CropEntity crop) {
    if (crop.imageUrl != null && crop.imageUrl!.isNotEmpty) {
      final String imageUrl = crop.imageUrl!;
      if (imageUrl.startsWith('data:image')) {
        final ImageProvider<Object>? memoryProvider = _memoryImageProvider(imageUrl);
        if (memoryProvider != null) {
          return Image(
            image: memoryProvider,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _heroPlaceholder(),
          );
        }
      }
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _heroPlaceholder(),
      );
    }

    if (crop.localImagePath != null && crop.localImagePath!.isNotEmpty) {
      return Image.file(
        File(crop.localImagePath!),
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _heroPlaceholder(),
      );
    }

    return _heroPlaceholder();
  }

  Widget _heroPlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      color: AppColors.primaryGreenLight.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(
          Icons.grass_outlined,
          color: AppColors.primaryGreenDark,
          size: 48,
        ),
      ),
    );
  }

  ImageProvider<Object>? _memoryImageProvider(String dataUri) {
    final int commaIndex = dataUri.indexOf(',');
    if (commaIndex <= 0 || commaIndex >= dataUri.length - 1) {
      return null;
    }
    try {
      return MemoryImage(base64Decode(dataUri.substring(commaIndex + 1)));
    } catch (_) {
      return null;
    }
  }

  Widget _statusChip(CropEntity crop) {
    final bool expiringSoon = crop.expiresAt != null &&
        crop.status == 'active' &&
        crop.expiresAt!.difference(DateTime.now()).inDays <= 2;

    String label;
    Color bg;
    Color fg;
    if (crop.status == 'sold') {
      label = 'Sold';
      bg = const Color(0xFFE5E7EB);
      fg = const Color(0xFF4B5563);
    } else if (expiringSoon) {
      label = 'Expiring soon';
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFF9A3412);
    } else {
      label = 'Active';
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'NunitoSans',
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

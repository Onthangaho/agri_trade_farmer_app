// lib/shared/widgets/crop_card.dart
/// Reusable crop listing card with status, sync indicator, and hero animation.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../features/crops/domain/entities/crop_entity.dart';

class CropCard extends StatelessWidget {
  const CropCard({
    super.key,
    required this.crop,
    this.index = 0,
    this.onTap,
  });

  final CropEntity crop;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isPendingSync = !crop.synced;
    final _StatusPresentation statusPresentation = _buildStatusPresentation(crop);

    return Hero(
      tag: 'crop_${crop.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x15000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                _buildImage(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        crop.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.navyText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${crop.quantity.toStringAsFixed(crop.quantity % 1 == 0 ? 0 : 1)} ${crop.unit}',
                        style: const TextStyle(
                          fontFamily: 'Nunito Sans',
                          fontSize: 14,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R ${crop.pricePerUnit.toStringAsFixed(2)} / ${crop.unit}',
                        style: const TextStyle(
                          fontFamily: 'Nunito Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          _buildStatusChip(statusPresentation),
                          const SizedBox(width: 8),
                          Icon(
                            isPendingSync ? Icons.cloud_off : Icons.cloud_done,
                            size: 18,
                            color: isPendingSync ? AppColors.accentAmber : AppColors.successGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    const BorderRadius radius = BorderRadius.all(Radius.circular(12));
    final String semanticLabel = '${crop.name} crop image';

    if (crop.imageUrl != null && crop.imageUrl!.isNotEmpty) {
      return Semantics(
        label: semanticLabel,
        image: true,
        child: ClipRRect(
          borderRadius: radius,
          child: CachedNetworkImage(
            imageUrl: crop.imageUrl!,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (BuildContext context, String _) => Container(
              width: 80,
              height: 80,
              color: AppColors.surfaceMist,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (BuildContext context, String imageUrl, Object error) =>
                _placeholderImage(),
          ),
        ),
      );
    }

    if (crop.localImagePath != null && crop.localImagePath!.isNotEmpty) {
      final File imageFile = File(crop.localImagePath!);
      return Semantics(
        label: semanticLabel,
        image: true,
        child: ClipRRect(
          borderRadius: radius,
          child: Image.file(
            imageFile,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
              return _placeholderImage();
            },
          ),
        ),
      );
    }

    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceMist,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_outlined, color: AppColors.mutedText),
    );
  }

  Widget _buildStatusChip(_StatusPresentation status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Nunito Sans',
        ),
      ),
    );
  }

  _StatusPresentation _buildStatusPresentation(CropEntity crop) {
    if (crop.isExpired) {
      return const _StatusPresentation(
        label: 'Expired',
        background: Color(0xFFFEE2E2),
        foreground: Color(0xFF991B1B),
      );
    }

    if (crop.status == 'sold') {
      return const _StatusPresentation(
        label: 'Sold',
        background: Color(0xFFE5E7EB),
        foreground: Color(0xFF4B5563),
      );
    }

    if (crop.expiresAt != null && crop.expiresAt!.difference(DateTime.now()).inDays <= 2) {
      return const _StatusPresentation(
        label: 'Expiring soon',
        background: Color(0xFFFFEDD5),
        foreground: Color(0xFF9A3412),
      );
    }

    return const _StatusPresentation(
      label: 'Active',
      background: Color(0xFFDCFCE7),
      foreground: Color(0xFF166534),
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

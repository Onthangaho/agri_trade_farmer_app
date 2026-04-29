// lib/shared/widgets/crop_card.dart
/// Reusable crop listing card (fixed-height layout, ellipsis-safe text).

import 'dart:convert';
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
    this.layout = CropCardLayout.vertical,
  });

  final CropEntity crop;
  final int index;
  final VoidCallback? onTap;
  final CropCardLayout layout;

  @override
  Widget build(BuildContext context) {
    final bool isHorizontal = layout == CropCardLayout.horizontal;
    return Hero(
      tag: 'crop_${crop.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: isHorizontal ? 122 : 236,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x15000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: isHorizontal ? _buildHorizontalContent() : _buildVerticalContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _buildImageSection(isHorizontal: false)),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: _buildInfoColumn(),
        ),
      ],
    );
  }

  Widget _buildHorizontalContent() {
    return Padding(
      padding: const EdgeInsets.all(9),
      child: Row(
        children: <Widget>[
          _buildImageSection(isHorizontal: true),
          const SizedBox(width: 10),
          Expanded(
            child: _buildInfoColumn(isHorizontal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn({bool isHorizontal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          crop.name,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.navyText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isHorizontal ? 3 : 4),
        Text(
          '${crop.quantity.toStringAsFixed(crop.quantity % 1 == 0 ? 0 : 1)} ${crop.unit}',
          style: const TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 13,
            color: AppColors.mutedText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isHorizontal ? 5 : 6),
        Text(
          'R ${crop.pricePerUnit.toStringAsFixed(2)} / ${crop.unit}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.primaryGreen,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isHorizontal ? 6 : 8),
        Wrap(
          spacing: 6,
          runSpacing: isHorizontal ? 2 : 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _StatusChip(status: crop.isExpired ? 'expired' : crop.status),
            if (!crop.synced) const _SyncPendingBadge(),
          ],
        ),
      ],
    );
  }

  Widget _buildImageSection({required bool isHorizontal}) {
    return Container(
      width: isHorizontal ? 90 : double.infinity,
      height: isHorizontal ? double.infinity : null,
      decoration: BoxDecoration(
        color: AppColors.surfaceMist,
        borderRadius: isHorizontal
            ? BorderRadius.circular(12)
            : const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
      ),
      child: ClipRRect(
        borderRadius: isHorizontal
            ? BorderRadius.circular(12)
            : const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final String? imageUrl = crop.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Handle base64 data-uri stored locally to avoid network fetch.
      if (imageUrl.startsWith('data:image')) {
        final ImageProvider<Object>? provider = _memoryImageProvider(imageUrl);
        if (provider != null) {
          return Image(
            image: provider,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => const _ImagePlaceholder(),
          );
        }

        // If the data-uri can't be decoded, don't try to fetch it as a URL.
        return const _ImagePlaceholder();
      }

      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (BuildContext context, String _) => const _ImagePlaceholder(),
        errorWidget: (BuildContext context, String _, Object error) => const _ImagePlaceholder(),
      );
    }

    if (crop.localImagePath != null && crop.localImagePath!.isNotEmpty) {
      final File file = File(crop.localImagePath!);
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => const _ImagePlaceholder(),
      );
    }

    return const _ImagePlaceholder();
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
}

enum CropCardLayout {
  horizontal,
  vertical,
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: AppColors.mutedText,
      ),
    );
  }
}

class _SyncPendingBadge extends StatelessWidget {
  const _SyncPendingBadge();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.cloud_off,
      size: 18,
      color: AppColors.accentAmber,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final String normalized = status.toLowerCase();

    final Color statusColor;
    final String statusLabel;

    if (normalized == 'sold') {
      statusColor = AppColors.mutedText;
      statusLabel = 'Sold';
    } else if (normalized == 'expired') {
      statusColor = AppColors.errorTerracotta;
      statusLabel = 'Expired';
    } else if (normalized == 'active') {
      statusColor = AppColors.successGreen;
      statusLabel = 'Active';
    } else {
      statusColor = AppColors.mutedText;
      statusLabel = status.isEmpty
          ? 'Active'
          : '${status[0].toUpperCase()}${status.substring(1)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

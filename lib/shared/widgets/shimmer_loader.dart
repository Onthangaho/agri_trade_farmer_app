// lib/shared/widgets/shimmer_loader.dart
/// Generic shimmer skeleton used while asynchronous content is loading.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';

class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.borderRadius = 8,
  });

  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceMist,
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceMist,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

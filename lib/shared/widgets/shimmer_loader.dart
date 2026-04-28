// lib/shared/widgets/shimmer_loader.dart
/// Generic shimmer skeleton used while asynchronous content is loading.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: child,
    );
  }
}

class ShimmerCropCard extends StatelessWidget {
  const ShimmerCropCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _ShimmerBlock(width: 120, height: 14),
                  const SizedBox(height: 8),
                  _ShimmerBlock(width: 90, height: 12),
                  const SizedBox(height: 8),
                  _ShimmerBlock(width: 110, height: 12),
                  const SizedBox(height: 10),
                  _ShimmerBlock(width: 70, height: 24, radius: 999),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white),
        title: const _ShimmerBlock(width: 140, height: 14),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: _ShimmerBlock(width: 180, height: 12),
        ),
        trailing: const _ShimmerBlock(width: 56, height: 24, radius: 999),
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

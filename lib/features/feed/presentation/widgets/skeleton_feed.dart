import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/design/design_tokens.dart';

class SkeletonFeed extends StatelessWidget {
  const SkeletonFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: GColors.surface,
      highlightColor: GColors.elevated,
      child: Container(
        color: GColors.surface,
        child: Stack(
          children: [
            // Fake video background
            Positioned.fill(
              child: Container(color: GColors.surface),
            ),

            // Fake info bottom-left
            Positioned(
              left: GSpacing.md,
              bottom: GSpacing.xxl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 120, height: 12),
                  const SizedBox(height: 8),
                  _SkeletonBox(width: 200, height: 14),
                  const SizedBox(height: 8),
                  _SkeletonBox(width: 160, height: 14),
                ],
              ),
            ),

            // Fake actions right
            Positioned(
              right: GSpacing.md,
              bottom: 120,
              child: Column(
                children: List.generate(4, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: GSpacing.lg),
                    child: _SkeletonBox(width: 48, height: 48, circular: true),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final bool circular;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: GColors.elevated,
        borderRadius: BorderRadius.circular(
          circular ? GRadius.full : GRadius.sm,
        ),
      ),
    );
  }
}

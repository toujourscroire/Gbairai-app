import 'dart:ui';
import 'package:flutter/material.dart';
import 'design_tokens.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurSigma = GBlur.card,
    this.backgroundColor,
    this.borderColor,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(GRadius.lg);

    Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(GSpacing.md),
          decoration: BoxDecoration(
            color: backgroundColor ?? GColors.glassBg,
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? GColors.glassBorder,
              width: 1.0,
            ),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(GRadius.xl)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: GBlur.overlay, sigmaY: GBlur.overlay),
        child: Container(
          decoration: const BoxDecoration(
            color: GColors.glassBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(GRadius.xl)),
            border: Border(
              top: BorderSide(color: GColors.glassBorder, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: GSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GColors.textTertiary,
                  borderRadius: BorderRadius.circular(GRadius.full),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: GSpacing.md),
                Text(title!, style: GTextStyle.headlineSmall),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// Overlay gradient pour les vidéos en plein écran
class VideoGradientOverlay extends StatelessWidget {
  const VideoGradientOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GColors.videoGradientTop,
            Colors.transparent,
            Colors.transparent,
            GColors.videoGradientBottom,
          ],
          stops: [0.0, 0.15, 0.6, 1.0],
        ),
      ),
    );
  }
}

// Conteneur avec glow orange pour les éléments Gbairai actifs
class GbairaiGlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;

  const GbairaiGlowContainer({
    super.key,
    required this.child,
    this.glowColor = GColors.orangeGlow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

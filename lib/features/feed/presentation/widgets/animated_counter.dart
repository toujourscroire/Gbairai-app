import 'package:flutter/material.dart';
import '../../../../core/design/design_tokens.dart';

class GbairaiCounter extends StatefulWidget {
  final int count;
  final TextStyle? style;
  final Color? glowColor;

  const GbairaiCounter({
    super.key,
    required this.count,
    this.style,
    this.glowColor,
  });

  @override
  State<GbairaiCounter> createState() => _GbairaiCounterState();
}

class _GbairaiCounterState extends State<GbairaiCounter> {
  @override
  Widget build(BuildContext context) {
    final formatted = _formatCount(widget.count);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: GDuration.normal,
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              )),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            formatted,
            key: ValueKey(formatted),
            style: (widget.style ?? GTextStyle.counterLarge).copyWith(
              shadows: [
                Shadow(
                  color: widget.glowColor ?? GColors.orangeGlow,
                  blurRadius: 20,
                ),
              ],
            ),
          ),
        ),
        Text(
          'vues en ce moment',
          style: GTextStyle.labelSmall.copyWith(
            color: GColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class CompactCounter extends StatelessWidget {
  final int count;
  final Color? color;

  const CompactCounter({super.key, required this.count, this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: GDuration.fast,
      child: Text(
        _format(count),
        key: ValueKey(count),
        style: GTextStyle.counter.copyWith(color: color ?? GColors.textPrimary),
      ),
    );
  }

  String _format(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

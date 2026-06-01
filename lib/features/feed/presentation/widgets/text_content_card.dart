import 'package:flutter/material.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../shared/models/content_model.dart';
import 'content_actions_column.dart';
import 'content_info_row.dart';
import 'voice_reaction_sheet.dart';

// Fonds animés pour les statuts écrits
const _gradientBackgrounds = {
  'gradient_1': [Color(0xFFE85D04), Color(0xFF9B2226)],
  'gradient_2': [Color(0xFF7C3AED), Color(0xFFDB2777)],
  'gradient_3': [Color(0xFF0891B2), Color(0xFF059669)],
  'gradient_4': [Color(0xFFF59E0B), Color(0xFFEF4444)],
  'gradient_5': [Color(0xFF1E1E2E), Color(0xFF2D1B69)],
  'gradient_6': [Color(0xFF064E3B), Color(0xFF065F46)],
  'gradient_7': [Color(0xFF1E3A5F), Color(0xFF0C1B33)],
  'gradient_8': [Color(0xFF4C1D95), Color(0xFF1E1B4B)],
  'gradient_9': [Color(0xFF7F1D1D), Color(0xFF450A0A)],
  'gradient_10': [Color(0xFF134E4A), Color(0xFF042F2E)],
  'gradient_11': [Color(0xFF78350F), Color(0xFF451A03)],
  'gradient_12': [Color(0xFF1C1917), Color(0xFF292524)],
};

class TextContentCard extends StatelessWidget {
  final ContentModel content;
  final bool isActive;
  final ValueChanged<String> onReact;

  const TextContentCard({
    super.key,
    required this.content,
    required this.isActive,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _gradientBackgrounds[content.textBackground] ??
        _gradientBackgrounds['gradient_1']!;

    final fontSize = switch (content.textSize) {
      'large' => 28.0,
      'xlarge' => 36.0,
      _ => 20.0,
    };

    return GestureDetector(
      onDoubleTap: () => onReact('gbairai'),
      child: Stack(
        children: [
          // ── Fond gradient animé ──────────────────────────────────────
          Positioned.fill(
            child: _AnimatedGradientBackground(colors: colors),
          ),

          // ── Texte centré ─────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
              child: Text(
                content.caption ?? '',
                textAlign: TextAlign.center,
                style: GTextStyle.displaySmall.copyWith(
                  fontSize: fontSize,
                  fontFamily: _fontFamily(content.textFont),
                  height: 1.4,
                  shadows: [
                    const Shadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Actions droite ────────────────────────────────────────────
          Positioned(
            right: GSpacing.md,
            bottom: 120,
            child: ContentActionsColumn(
              content: content,
              onReact: onReact,
              onVoiceReact: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => VoiceReactionSheet(contentId: content.id),
              ),
            ),
          ),

          // ── Info bas-gauche ───────────────────────────────────────────
          Positioned(
            left: GSpacing.md,
            right: 80,
            bottom: GSpacing.xxl,
            child: ContentInfoRow(content: content),
          ),
        ],
      ),
    );
  }

  String _fontFamily(String font) {
    return switch (font) {
      'sora' => GFont.sora,
      _ => GFont.inter,
    };
  }
}

class _AnimatedGradientBackground extends StatefulWidget {
  final List<Color> colors;
  const _AnimatedGradientBackground({required this.colors});

  @override
  State<_AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<_AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _begin;
  late Animation<Alignment> _end;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _begin = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.bottomLeft,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _end = AlignmentTween(
      begin: Alignment.bottomRight,
      end: Alignment.topRight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: _begin.value,
            end: _end.value,
            colors: widget.colors,
          ),
        ),
      ),
    );
  }
}

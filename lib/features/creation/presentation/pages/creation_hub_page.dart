import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/animations/haptic_service.dart';

class CreationHubPage extends StatelessWidget {
  const CreationHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.void_,
      appBar: AppBar(
        title: const Text('Crée ton Gbairai'),
        backgroundColor: GColors.void_,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'C\'est quoi ton Gbairai ?',
                style: GTextStyle.displaySmall,
              ).animate().fadeIn().slideX(begin: -0.1),

              const SizedBox(height: GSpacing.sm),

              Text(
                'Choisis ton format',
                style: GTextStyle.bodyMedium.copyWith(
                  color: GColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: GSpacing.xxl),

              // ── Vidéo ─────────────────────────────────────────────────
              _CreationOption(
                emoji: '🎥',
                title: 'Vidéo',
                subtitle: '15s jusqu\'à 3 minutes · Plein écran',
                gradientColors: const [Color(0xFFE85D04), Color(0xFF9B2226)],
                onTap: () {
                  GHaptics.medium();
                  context.push('/create/video');
                },
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: GSpacing.md),

              // ── Statut écrit ───────────────────────────────────────────
              _CreationOption(
                emoji: '✍️',
                title: 'Statut',
                subtitle: '280 caractères · Fond animé premium',
                gradientColors: const [Color(0xFF7C3AED), Color(0xFFDB2777)],
                onTap: () {
                  GHaptics.medium();
                  context.push('/create/text');
                },
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

              const SizedBox(height: GSpacing.md),

              // ── Vocal ──────────────────────────────────────────────────
              _CreationOption(
                emoji: '🎤',
                title: 'Vocal',
                subtitle: '5s jusqu\'à 2 minutes · Cover animée',
                gradientColors: const [Color(0xFF0891B2), Color(0xFF059669)],
                onTap: () {
                  GHaptics.medium();
                  context.push('/create/voice');
                },
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              const Spacer(),

              Center(
                child: Text(
                  'Chaque Gbairai peut devenir viral 🔥',
                  style: GTextStyle.bodySmall.copyWith(
                    color: GColors.textTertiary,
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreationOption extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _CreationOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              gradientColors[0].withValues(alpha: 0.15),
              gradientColors[1].withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(GRadius.xl),
          border: Border.all(
            color: gradientColors[0].withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Emoji avec fond coloré
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(GRadius.xl),
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 40)),
              ),
            ),

            const SizedBox(width: GSpacing.lg),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GTextStyle.headlineSmall),
                  const SizedBox(height: GSpacing.xs),
                  Text(
                    subtitle,
                    style: GTextStyle.bodySmall,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: GSpacing.md),
              child: Icon(
                Icons.arrow_forward_ios,
                color: gradientColors[0],
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/glassmorphism.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../shared/models/alert_model.dart';
import '../providers/alert_provider.dart';
import '../../../feed/presentation/widgets/animated_counter.dart';

class AlertScreenPage extends ConsumerStatefulWidget {
  final String alertId;
  const AlertScreenPage({super.key, required this.alertId});

  @override
  ConsumerState<AlertScreenPage> createState() => _AlertScreenPageState();
}

class _AlertScreenPageState extends ConsumerState<AlertScreenPage>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _badgeController;
  late Animation<Color?> _bgColor;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _bgColor = ColorTween(
      begin: const Color(0xFF8B0000),
      end: const Color(0xFFE85D04),
    ).animate(CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bgController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertAsync = ref.watch(alertStreamProvider);

    return alertAsync.when(
      data: (alert) {
        if (alert == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
          return const SizedBox.shrink();
        }
        return _buildAlert(context, alert);
      },
      loading: () => const Scaffold(
        backgroundColor: GColors.void_,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(GColors.orange),
          ),
        ),
      ),
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAlert(BuildContext context, AlertModel alert) {
    final liveCount = ref.watch(liveViewCountProvider(alert.contentId));

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgColor,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [
                _bgColor.value ?? GColors.red,
                GColors.void_,
              ],
            ),
          ),
          child: child,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(GSpacing.lg),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: GColors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _badgeController,
                      builder: (_, __) => Opacity(
                        opacity: 0.5 + _badgeController.value * 0.5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GSpacing.md,
                            vertical: GSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: GColors.red,
                            borderRadius: BorderRadius.circular(GRadius.full),
                            boxShadow: GShadow.redGlow,
                          ),
                          child: Text(
                            '${alert.level.badge} ${alert.level.label.toUpperCase()}',
                            style: GTextStyle.labelLarge.copyWith(
                              fontFamily: GFont.sora,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              // ── Titre généré par IA ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
                child: Text(
                  alert.titleGenerated,
                  textAlign: TextAlign.center,
                  style: GTextStyle.displaySmall.copyWith(
                    shadows: [
                      Shadow(
                        color: GColors.red.withValues(alpha: 0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: GSpacing.lg),

              // ── Compteur live ─────────────────────────────────────────
              liveCount.when(
                data: (count) => GbairaiCounter(count: count),
                loading: () => GbairaiCounter(count: alert.sentCount),
                error: (_, __) => GbairaiCounter(count: alert.sentCount),
              ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),

              const SizedBox(height: GSpacing.lg),

              // ── Aperçu contenu (55% écran) ────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: GSpacing.lg),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(GRadius.xl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(GRadius.xl),
                      child: Stack(
                        children: [
                          // Thumbnail / preview
                          if (alert.contentThumbnailUrl != null)
                            Positioned.fill(
                              child: Image.network(
                                alert.contentThumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const _ContentPlaceholder(),
                              ),
                            )
                          else
                            const Positioned.fill(child: _ContentPlaceholder()),

                          // Gradient overlay
                          const Positioned.fill(
                            child: VideoGradientOverlay(),
                          ),

                          // Live réactions ticker
                          const Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _LiveReactionsTicker(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: GSpacing.lg),

              // ── CTAs ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        context.pop();
                        context.push('/content/${alert.contentId}');
                      },
                      child: const Text('👀 Voir le Gbairai'),
                    ),

                    const SizedBox(height: GSpacing.sm),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.pop();
                              context.push('/content/${alert.contentId}?action=voice_react');
                            },
                            child: const Text('🎤 Réagir'),
                          ),
                        ),
                        const SizedBox(width: GSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {/* WhatsApp share */},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                            ),
                            child: const Text('WhatsApp'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

              const SizedBox(height: GSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentPlaceholder extends StatefulWidget {
  const _ContentPlaceholder();

  @override
  State<_ContentPlaceholder> createState() => _ContentPlaceholderState();
}

class _ContentPlaceholderState extends State<_ContentPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GColors.red.withValues(alpha: 0.3 + _c.value * 0.2),
              GColors.orange.withValues(alpha: 0.2 + _c.value * 0.2),
            ],
          ),
        ),
        child: const Center(
          child: Text('🔥', style: TextStyle(fontSize: 60)),
        ),
      ),
    );
  }
}

class _LiveReactionsTicker extends StatefulWidget {
  const _LiveReactionsTicker();

  @override
  State<_LiveReactionsTicker> createState() => _LiveReactionsTickerState();
}

class _LiveReactionsTickerState extends State<_LiveReactionsTicker> {
  final _emojis = ['🔥', '😂', '😱', '💰', '🤌', '😤'];
  final _names = ['Konan', 'Aya', 'Serge', 'Bintou', 'Kouassi', 'Mariama'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(GRadius.xl),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 20,
          itemBuilder: (_, i) {
            final emoji = _emojis[Random().nextInt(_emojis.length)];
            final name = _names[Random().nextInt(_names.length)];
            return Padding(
              padding: const EdgeInsets.only(right: GSpacing.md),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    name,
                    style: GTextStyle.bodySmall.copyWith(
                      color: GColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

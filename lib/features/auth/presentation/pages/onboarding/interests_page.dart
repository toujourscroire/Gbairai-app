import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/design/design_tokens.dart';
import '../../../../../core/design/animations/haptic_service.dart';
import '../../../../../routing/route_names.dart';

const _categories = [
  ('Humour', '😂'), ('Sport', '⚽'), ('Music', '🎵'), ('People', '👥'),
  ('Food', '🍽️'), ('Mode', '👗'), ('Quartier', '🏘️'), ('Politique', '🗳️'),
  ('Business', '💼'), ('Culture', '🎭'), ('Tech', '💻'), ('Religion', '🙏'),
];

class InterestsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;
  const InterestsPage({super.key, required this.userData});

  @override
  ConsumerState<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends ConsumerState<InterestsPage> {
  final Set<String> _selected = {};

  void _toggle(String category) {
    GHaptics.light();
    setState(() {
      if (_selected.contains(category)) {
        _selected.remove(category);
      } else {
        _selected.add(category);
      }
    });
  }

  void _next() {
    if (_selected.length < 3) return;
    GHaptics.success();
    context.push(
      RouteNames.onboardingNotifications,
      extra: {...widget.userData, 'interests': _selected.toList()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selected.length >= 3;

    return Scaffold(
      backgroundColor: GColors.void_,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: GSpacing.xl),
              _OnboardingProgress(step: 2),
              const SizedBox(height: GSpacing.xl),

              Text(
                'T\'es chaud pour quoi ?',
                style: GTextStyle.displaySmall,
              ).animate().fadeIn(),

              const SizedBox(height: GSpacing.sm),

              Text(
                'Choisis au moins 3 pour calibrer ton Gbairai',
                style: GTextStyle.bodyMedium.copyWith(
                  color: GColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 100.ms),

              // Compteur
              const SizedBox(height: GSpacing.md),
              AnimatedContainer(
                duration: GDuration.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: GSpacing.md,
                  vertical: GSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: canContinue
                      ? GColors.orange.withValues(alpha: 0.15)
                      : GColors.surface,
                  borderRadius: BorderRadius.circular(GRadius.full),
                  border: Border.all(
                    color: canContinue ? GColors.orange : GColors.border,
                  ),
                ),
                child: Text(
                  canContinue
                      ? '✅ ${_selected.length} sélectionnées — Top !'
                      : '${_selected.length}/3 minimum',
                  style: GTextStyle.labelMedium.copyWith(
                    color: canContinue ? GColors.orange : GColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: GSpacing.xl),

              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: GSpacing.sm,
                    mainAxisSpacing: GSpacing.sm,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final (label, emoji) = _categories[i];
                    final isSelected = _selected.contains(label);
                    return GestureDetector(
                      onTap: () => _toggle(label),
                      child: AnimatedContainer(
                        duration: GDuration.fast,
                        curve: Curves.elasticOut,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? GColors.orange.withValues(alpha: 0.2)
                              : GColors.surface,
                          borderRadius: BorderRadius.circular(GRadius.lg),
                          border: Border.all(
                            color: isSelected ? GColors.orange : GColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? GShadow.orangeGlow : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.2 : 1.0,
                              duration: GDuration.fast,
                              child: Text(emoji,
                                style: const TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(height: GSpacing.xs),
                            Text(
                              label,
                              style: GTextStyle.labelSmall.copyWith(
                                color: isSelected
                                    ? GColors.orange
                                    : GColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: Duration(milliseconds: i * 50))
                        .fadeIn()
                        .scale(begin: const Offset(0.8, 0.8));
                  },
                ),
              ),

              ElevatedButton(
                onPressed: canContinue ? _next : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canContinue ? GColors.orange : GColors.surface,
                  foregroundColor: canContinue
                      ? GColors.textPrimary
                      : GColors.textTertiary,
                ),
                child: Text(
                  canContinue
                      ? 'Allons-y 🔥'
                      : 'Sélectionne au moins 3',
                ),
              ).animate().fadeIn(),

              const SizedBox(height: GSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingProgress extends StatelessWidget {
  final int step;
  const _OnboardingProgress({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: GDuration.normal,
              height: 4,
              decoration: BoxDecoration(
                color: i < step ? GColors.orange : GColors.border,
                borderRadius: BorderRadius.circular(GRadius.full),
              ),
            ),
          ),
        );
      }),
    );
  }
}

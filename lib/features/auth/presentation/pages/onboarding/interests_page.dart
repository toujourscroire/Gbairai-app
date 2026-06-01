import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/design/design_tokens.dart';
import '../../../../../core/design/animations/haptic_service.dart';
import '../../../../../routing/route_names.dart';

// Catégories avec icônes Material au lieu d'emoji
const _categories = [
  ('Humour',    Icons.sentiment_very_satisfied_outlined),
  ('Sport',     Icons.sports_soccer_outlined),
  ('Musique',   Icons.music_note_outlined),
  ('People',    Icons.groups_outlined),
  ('Food',      Icons.restaurant_outlined),
  ('Mode',      Icons.checkroom_outlined),
  ('Quartier',  Icons.location_city_outlined),
  ('Politique', Icons.account_balance_outlined),
  ('Business',  Icons.trending_up_outlined),
  ('Culture',   Icons.theater_comedy_outlined),
  ('Tech',      Icons.devices_outlined),
  ('Spirituel', Icons.auto_awesome_outlined),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  GSpacing.xl, GSpacing.lg, GSpacing.xl, 0),
              child: _OnboardingHeader(step: 2, totalSteps: 3),
            ),

            // ── Titre ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  GSpacing.xl, GSpacing.xl, GSpacing.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tes centres\nd\'intérêt',
                    style: GTextStyle.displaySmall,
                  ).animate().fadeIn().slideY(
                        begin: 0.15,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: GSpacing.sm),

                  Text(
                    'Sélectionne au moins 3 pour personnaliser ton feed',
                    style: GTextStyle.bodyLarge.copyWith(
                      color: GColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: GSpacing.md),

                  // Compteur discret
                  _SelectionCounter(
                    selected: _selected.length,
                    canContinue: canContinue,
                  ).animate().fadeIn(delay: 150.ms),
                ],
              ),
            ),

            const SizedBox(height: GSpacing.lg),

            // ── Grille ───────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.05,
                    crossAxisSpacing: GSpacing.sm,
                    mainAxisSpacing: GSpacing.sm,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final (label, icon) = _categories[i];
                    final isSelected = _selected.contains(label);
                    return _CategoryTile(
                      label: label,
                      icon: icon,
                      isSelected: isSelected,
                      onTap: () => _toggle(label),
                    )
                        .animate(delay: Duration(milliseconds: i * 40))
                        .fadeIn(duration: 300.ms)
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          duration: 300.ms,
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
              ),
            ),

            // ── CTA ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  GSpacing.xl, GSpacing.md, GSpacing.xl, GSpacing.lg),
              child: _ContinueButton(
                enabled: canContinue,
                onTap: _next,
                label: 'Continuer',
              ).animate().fadeIn(delay: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _OnboardingHeader extends StatelessWidget {
  final int step;
  final int totalSteps;

  const _OnboardingHeader({required this.step, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Étape $step',
              style: GTextStyle.labelMedium.copyWith(
                color: GColors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' sur $totalSteps',
              style: GTextStyle.labelMedium.copyWith(
                color: GColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: GSpacing.sm),
        Row(
          children: List.generate(totalSteps, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
                child: AnimatedContainer(
                  duration: GDuration.normal,
                  height: 3,
                  decoration: BoxDecoration(
                    color: i < step ? GColors.orange : GColors.border,
                    borderRadius: BorderRadius.circular(GRadius.full),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SelectionCounter extends StatelessWidget {
  final int selected;
  final bool canContinue;

  const _SelectionCounter({required this.selected, required this.canContinue});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: GDuration.fast,
      padding: const EdgeInsets.symmetric(
        horizontal: GSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: canContinue
            ? GColors.orange.withValues(alpha: 0.1)
            : GColors.surface,
        borderRadius: BorderRadius.circular(GRadius.full),
        border: Border.all(
          color: canContinue
              ? GColors.orange.withValues(alpha: 0.35)
              : GColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: GDuration.fast,
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: canContinue ? GColors.orange : GColors.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: GSpacing.sm),
          Text(
            canContinue
                ? '$selected sélectionnées'
                : '$selected / 3 minimum',
            style: GTextStyle.labelSmall.copyWith(
              color: canContinue ? GColors.orange : GColors.textTertiary,
              fontWeight: canContinue ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: GDuration.fast,
        decoration: BoxDecoration(
          color: isSelected
              ? GColors.orange.withValues(alpha: 0.12)
              : GColors.surface,
          borderRadius: BorderRadius.circular(GRadius.lg),
          border: Border.all(
            color: isSelected
                ? GColors.orange.withValues(alpha: 0.5)
                : GColors.border,
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: GDuration.fast,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? GColors.orange.withValues(alpha: 0.2)
                    : GColors.elevated,
                borderRadius: BorderRadius.circular(GRadius.md),
              ),
              child: Icon(
                icon,
                color: isSelected ? GColors.orange : GColors.textTertiary,
                size: 18,
              ),
            ),
            const SizedBox(height: GSpacing.xs),
            Text(
              label,
              style: GTextStyle.labelSmall.copyWith(
                color: isSelected ? GColors.orange : GColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  final String label;

  const _ContinueButton({
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.enabled ? GColors.orange : GColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: widget.enabled ? null : Border.all(color: GColors.border),
            boxShadow: widget.enabled && !_pressed
                ? [
                    BoxShadow(
                      color: GColors.orange.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GTextStyle.buttonPrimary.copyWith(
                color: widget.enabled
                    ? GColors.textPrimary
                    : GColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

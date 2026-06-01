import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/animations/haptic_service.dart';
import '../../../../routing/route_names.dart';
import '../providers/auth_provider.dart';

class AuthChoicePage extends ConsumerWidget {
  const AuthChoicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: GColors.void_,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: GSpacing.md, vertical: GSpacing.sm),
              child: Row(
                children: [
                  _BackButton(onTap: () => context.pop()),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: GSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: GSpacing.lg),

                    Text(
                      'Connexion',
                      style: GTextStyle.displaySmall,
                    ).animate().fadeIn().slideY(
                          begin: 0.15,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: GSpacing.sm),

                    Text(
                      'Choisis ta méthode',
                      style: GTextStyle.bodyLarge.copyWith(
                        color: GColors.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: GSpacing.xxl),

                    // ── Téléphone (méthode principale) ──────────────────
                    _AuthOption(
                      iconWidget: const _PhoneIcon(),
                      label: 'Numéro CI',
                      subtitle: 'Recommandé · Code SMS',
                      isPrimary: true,
                      isLoading: isLoading,
                      onTap: () {
                        GHaptics.light();
                        context.push(RouteNames.authPhone);
                      },
                    ).animate().fadeIn(delay: 200.ms).slideY(
                          begin: 0.2,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: GSpacing.md),

                    // ── Séparateur ──────────────────────────────────────
                    _Divider().animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: GSpacing.md),

                    // ── Apple Sign-In (iOS seulement) ───────────────────
                    if (Platform.isIOS) ...[
                      _AuthOption(
                        iconWidget: const _AppleIcon(),
                        label: 'Apple',
                        subtitle: 'Face ID / Touch ID',
                        isLoading: isLoading,
                        onTap: () async {
                          GHaptics.medium();
                          await ref
                              .read(authControllerProvider.notifier)
                              .signInWithApple();
                          if (context.mounted) {
                            _handleAuthState(context, ref);
                          }
                        },
                      ).animate().fadeIn(delay: 350.ms).slideY(
                            begin: 0.2,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: GSpacing.sm),
                    ],

                    // ── Google ──────────────────────────────────────────
                    _AuthOption(
                      iconWidget: const _GoogleIcon(),
                      label: 'Google',
                      subtitle: 'Compte Google',
                      isLoading: isLoading,
                      onTap: () async {
                        GHaptics.medium();
                        await ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle();
                        if (context.mounted) {
                          _handleAuthState(context, ref);
                        }
                      },
                    ).animate().fadeIn(delay: 400.ms).slideY(
                          begin: 0.2,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: GSpacing.sm),

                    // ── Email ────────────────────────────────────────────
                    _AuthOption(
                      iconWidget: const _EmailIcon(),
                      label: 'Email',
                      subtitle: 'Email et mot de passe',
                      isLoading: isLoading,
                      onTap: () {
                        GHaptics.light();
                        context.push(RouteNames.authEmail);
                      },
                    ).animate().fadeIn(delay: 450.ms).slideY(
                          begin: 0.2,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const Spacer(),

                    // ── CGU ──────────────────────────────────────────────
                    Center(
                      child: Text(
                        'En continuant, tu acceptes nos Conditions\nd\'utilisation et Politique de confidentialité',
                        textAlign: TextAlign.center,
                        style: GTextStyle.bodySmall.copyWith(
                          color: GColors.textTertiary,
                          fontSize: 11,
                          height: 1.6,
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: GSpacing.lg),

                    // ── Loading ──────────────────────────────────────────
                    if (isLoading)
                      const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(GColors.orange),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAuthState(BuildContext context, WidgetRef ref) {
    final state = ref.read(authControllerProvider);
    if (state is AuthAuthenticated) {
      context.go(RouteNames.feed);
    } else if (state is AuthNeedsOnboarding) {
      context.go(RouteNames.onboardingIdentity, extra: state.authId);
    }
  }
}

// ── Bouton retour ────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: GColors.surface,
          borderRadius: BorderRadius.circular(GRadius.md),
          border: Border.all(color: GColors.border),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: GColors.textPrimary,
          size: 16,
        ),
      ),
    );
  }
}

// ── Option d'authentification ────────────────────────────────────────────────

class _AuthOption extends StatefulWidget {
  final Widget iconWidget;
  final String label;
  final String subtitle;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback? onTap;

  const _AuthOption({
    required this.iconWidget,
    required this.label,
    required this.subtitle,
    this.isPrimary = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<_AuthOption> createState() => _AuthOptionState();
}

class _AuthOptionState extends State<_AuthOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.md,
            vertical: GSpacing.md,
          ),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? GColors.orange.withValues(alpha: 0.08)
                : _pressed
                    ? GColors.elevated
                    : GColors.surface,
            borderRadius: BorderRadius.circular(GRadius.lg),
            border: Border.all(
              color: widget.isPrimary
                  ? GColors.orange.withValues(alpha: 0.4)
                  : GColors.border,
              width: widget.isPrimary ? 1.0 : 0.5,
            ),
          ),
          child: Row(
            children: [
              // Icône
              widget.iconWidget,

              const SizedBox(width: GSpacing.md),

              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: GTextStyle.labelLarge.copyWith(
                        color: widget.isPrimary
                            ? GColors.textPrimary
                            : GColors.textPrimary,
                        fontWeight: widget.isPrimary
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GTextStyle.bodySmall.copyWith(
                        color: widget.isPrimary
                            ? GColors.orange.withValues(alpha: 0.8)
                            : GColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: widget.isPrimary
                    ? GColors.orange.withValues(alpha: 0.6)
                    : GColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Séparateur ───────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 0.5, color: GColors.border),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
          child: Text(
            'ou',
            style: GTextStyle.bodySmall.copyWith(
              color: GColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 0.5, color: GColors.border),
        ),
      ],
    );
  }
}

// ── Icônes d'authentification ─────────────────────────────────────────────────

class _PhoneIcon extends StatelessWidget {
  const _PhoneIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: GColors.orange,
        borderRadius: BorderRadius.circular(GRadius.md),
      ),
      child: const Icon(
        Icons.phone_outlined,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: GColors.textPrimary,
        borderRadius: BorderRadius.circular(GRadius.md),
      ),
      child: const Icon(
        Icons.phone_iphone_rounded,
        color: GColors.void_,
        size: 22,
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: GColors.elevated,
        borderRadius: BorderRadius.circular(GRadius.md),
        border: Border.all(color: GColors.border),
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontFamily: GFont.sora,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4285F4),
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _EmailIcon extends StatelessWidget {
  const _EmailIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: GColors.elevated,
        borderRadius: BorderRadius.circular(GRadius.md),
        border: Border.all(color: GColors.border),
      ),
      child: const Icon(
        Icons.alternate_email_rounded,
        color: GColors.textSecondary,
        size: 22,
      ),
    );
  }
}

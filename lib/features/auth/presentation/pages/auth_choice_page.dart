import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/animations/haptic_service.dart';
import '../../../../core/design/glassmorphism.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: GColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: GSpacing.xl),

              Text(
                'Comment tu veux\nrejoindre ?',
                style: GTextStyle.displaySmall,
              ).animate().fadeIn().slideX(begin: -0.1),

              const SizedBox(height: GSpacing.sm),

              Text(
                'Choisis ta méthode de connexion',
                style: GTextStyle.bodyMedium.copyWith(
                  color: GColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: GSpacing.xxl),

              // ── Téléphone CI (méthode principale) ──────────────────
              _AuthOptionButton(
                icon: '🇨🇮',
                label: 'Numéro de téléphone CI',
                subtitle: 'Recommandé — Code SMS',
                isPrimary: true,
                onTap: isLoading ? null : () {
                  GHaptics.light();
                  context.push(RouteNames.authPhone);
                },
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

              const SizedBox(height: GSpacing.md),

              // ── Apple Sign-In (iOS seulement) ────────────────────────
              if (Platform.isIOS) ...[
                _AuthOptionButton(
                  icon: '🍎',
                  label: 'Continuer avec Apple',
                  subtitle: 'Face ID / Touch ID',
                  onTap: isLoading ? null : () async {
                    GHaptics.medium();
                    await ref.read(authControllerProvider.notifier).signInWithApple();
                    if (context.mounted) _handleAuthState(context, ref);
                  },
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                const SizedBox(height: GSpacing.md),
              ],

              // ── Google ───────────────────────────────────────────────
              _AuthOptionButton(
                icon: '🔵',
                label: 'Continuer avec Google',
                subtitle: 'Google Account',
                onTap: isLoading ? null : () async {
                  GHaptics.medium();
                  await ref.read(authControllerProvider.notifier).signInWithGoogle();
                  if (context.mounted) _handleAuthState(context, ref);
                },
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

              const SizedBox(height: GSpacing.md),

              // ── Email ─────────────────────────────────────────────────
              _AuthOptionButton(
                icon: '📧',
                label: 'Continuer avec Email',
                subtitle: 'Email et mot de passe',
                onTap: isLoading ? null : () {
                  GHaptics.light();
                  context.push(RouteNames.authEmail);
                },
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

              const Spacer(),

              // CGU
              Center(
                child: Text(
                  'En continuant, tu acceptes nos\nConditions d\'utilisation et Politique de confidentialité',
                  textAlign: TextAlign.center,
                  style: GTextStyle.bodySmall,
                ),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: GSpacing.lg),

              // Loading overlay
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(GColors.orange),
                  ),
                ),
            ],
          ),
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

class _AuthOptionButton extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _AuthOptionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: GSpacing.lg,
          vertical: GSpacing.md,
        ),
        backgroundColor: isPrimary
            ? GColors.orange.withValues(alpha: 0.15)
            : null,
        borderColor: isPrimary ? GColors.orange : GColors.glassBorder,
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: GSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GTextStyle.labelLarge),
                  Text(
                    subtitle,
                    style: GTextStyle.bodySmall,
                  ),
                ],
              ),
            ),
            if (isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GSpacing.sm,
                  vertical: GSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: GColors.orange,
                  borderRadius: BorderRadius.circular(GRadius.sm),
                ),
                child: Text(
                  'Recommandé',
                  style: GTextStyle.labelSmall.copyWith(
                    color: GColors.textPrimary,
                    fontSize: 10,
                  ),
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                color: GColors.textTertiary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

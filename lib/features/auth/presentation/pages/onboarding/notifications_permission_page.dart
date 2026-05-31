import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../../../core/services/supabase_service.dart';
import '../../../../../core/design/design_tokens.dart';
import '../../../../../core/design/animations/haptic_service.dart';
import '../../../../../core/services/fcm_service.dart';
import '../../../../../routing/route_names.dart';
import '../../providers/auth_provider.dart';

class NotificationsPermissionPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;
  const NotificationsPermissionPage({super.key, required this.userData});

  @override
  ConsumerState<NotificationsPermissionPage> createState() =>
      _NotificationsPermissionPageState();
}

class _NotificationsPermissionPageState
    extends ConsumerState<NotificationsPermissionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() => _isLoading = true);
    await GHaptics.gbairaiAlert();

    // Demande la permission iOS
    await FcmService.requestPermission();

    if (mounted) {
      await _completeOnboarding();
    }
  }

  Future<void> _skip() async {
    await _completeOnboarding();
  }

  Future<String?> _uploadAvatar(String localPath, String authId) async {
    try {
      final file = File(localPath);
      final bytes = await file.readAsBytes();
      final ext = localPath.split('.').last.toLowerCase();
      final storagePath = 'avatars/$authId/avatar.$ext';

      final client = SupabaseService.clientOrNull;
      if (client == null) return null;

      await client.storage
          .from('media')
          .uploadBinary(storagePath, bytes,
              fileOptions: FileOptions(
                contentType: 'image/$ext',
                upsert: true,
              ));

      return client.storage
          .from('media')
          .getPublicUrl(storagePath);
    } catch (_) {
      return null; // Avatar optionnel — l'onboarding continue sans
    }
  }

  Future<void> _completeOnboarding() async {
    final ud = widget.userData;
    setState(() => _isLoading = true);

    // Upload avatar si sélectionné
    String? avatarUrl;
    final avatarPath = ud['avatarPath'] as String?;
    if (avatarPath != null) {
      avatarUrl = await _uploadAvatar(avatarPath, ud['authId'] as String);
    }

    final success = await ref.read(authControllerProvider.notifier).completeOnboarding(
      authId: ud['authId'] as String,
      username: ud['username'] as String,
      displayName: ud['displayName'] as String,
      interests: (ud['interests'] as List<dynamic>).cast<String>(),
      avatarUrl: avatarUrl,
    );

    if (mounted) {
      if (success) {
        context.go(RouteNames.feed);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.void_,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: GSpacing.xl),
              _OnboardingProgress(step: 3),
              const Spacer(),

              // Animation cloche
              AnimatedBuilder(
                animation: _bellController,
                builder: (_, child) => Transform.rotate(
                  angle: (_bellController.value - 0.5) * 0.3,
                  child: child,
                ),
                child: const Text('🔔', style: TextStyle(fontSize: 80)),
              ).animate().scale(curve: Curves.elasticOut),

              const SizedBox(height: GSpacing.xl),

              Text(
                'Active les alertes',
                style: GTextStyle.displaySmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: GSpacing.md),

              Text(
                'Pour être le premier à voir les Gbairais 🚨\n\nOn t\'envoie max 3 alertes par jour, promis 👑',
                textAlign: TextAlign.center,
                style: GTextStyle.bodyLarge.copyWith(
                  color: GColors.textSecondary,
                  height: 1.6,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: GSpacing.xxl),

              // Preview notification
              Container(
                padding: const EdgeInsets.all(GSpacing.md),
                decoration: BoxDecoration(
                  color: GColors.surface,
                  borderRadius: BorderRadius.circular(GRadius.lg),
                  border: Border.all(color: GColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: GColors.orange,
                        borderRadius: BorderRadius.circular(GRadius.sm),
                      ),
                      child: const Center(
                        child: Text('⚡', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: GSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gbairai 🚨',
                            style: GTextStyle.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                          Text(
                            'Yopougon brûle — Tout Abidjan parle de ça',
                            style: GTextStyle.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).shimmer(delay: 600.ms),

              const Spacer(),

              // CTA Principal
              ElevatedButton(
                onPressed: _isLoading ? null : _activate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GColors.orange,
                  shadowColor: GColors.orangeGlow,
                  elevation: 8,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(GColors.textPrimary),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Activer — C\'est gratuit 🔔'),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: GSpacing.md),

              TextButton(
                onPressed: _isLoading ? null : _skip,
                child: Text(
                  'Plus tard',
                  style: GTextStyle.labelMedium.copyWith(
                    color: GColors.textTertiary,
                  ),
                ),
              ),

              const SizedBox(height: GSpacing.xl),
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/glassmorphism.dart';
import '../../../../core/design/animations/haptic_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  final String? userId; // null = mon profil

  const ProfilePage({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isMyProfile = userId == null;

    final user = isMyProfile && authState is AuthAuthenticated
        ? authState.user
        : null; // TODO: charger profil externe

    return Scaffold(
      backgroundColor: GColors.void_,
      body: CustomScrollView(
        slivers: [
          // ── Header avec bannière ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: GColors.void_,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Bannière
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          GColors.orange.withValues(alpha: 0.3),
                          GColors.void_,
                        ],
                      ),
                    ),
                  ),

                  // Avatar centré
                  Positioned(
                    bottom: GSpacing.lg,
                    left: GSpacing.xl,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: GColors.orange, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: GColors.surface,
                            backgroundImage: user?.avatarUrl != null
                                ? NetworkImage(user!.avatarUrl!)
                                : null,
                            child: user?.avatarUrl == null
                                ? const Text('👤', style: TextStyle(fontSize: 28))
                                : null,
                          ),
                        ),
                        const SizedBox(width: GSpacing.md),

                        // Nom + badge niveau
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user?.displayName ?? 'Chargement...',
                                  style: GTextStyle.headlineSmall,
                                ),
                                const SizedBox(width: GSpacing.xs),
                                Text(
                                  UserLevel.fromString(user?.level ?? 'debutant').emoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            Text(
                              '@${user?.username ?? ''}',
                              style: GTextStyle.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (isMyProfile)
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                )
              else
                ElevatedButton(
                  onPressed: () => GHaptics.medium(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
                  ),
                  child: const Text('Suivre'),
                ),
            ],
          ),

          // ── Bio ───────────────────────────────────────────────────────────
          if (user?.bio != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GSpacing.xl,
                  vertical: GSpacing.md,
                ),
                child: Text(user!.bio!, style: GTextStyle.bodyMedium),
              ).animate().fadeIn(),
            ),

          // ── Stats ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(label: 'Posts', value: user?.postsCount ?? 0),
                  _Stat(label: 'Abonnés', value: user?.followersCount ?? 0),
                  _Stat(label: 'Abonnements', value: user?.followingCount ?? 0),
                ],
              ).animate().fadeIn(delay: 100.ms),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: GSpacing.md),
          ),

          // ── Grille de contenus ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: GSpacing.sm),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                childAspectRatio: 0.75,
              ),
              itemCount: 30, // TODO: charger depuis API
              itemBuilder: (_, i) => _ContentGridItem(index: i)
                  .animate(delay: Duration(milliseconds: i * 20))
                  .fadeIn()
                  .scale(begin: const Offset(0.9, 0.9)),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _format(value),
          style: GTextStyle.headlineMedium.copyWith(color: GColors.textPrimary),
        ),
        Text(label, style: GTextStyle.bodySmall),
      ],
    );
  }

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ContentGridItem extends StatelessWidget {
  final int index;
  const _ContentGridItem({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GColors.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder
          Center(
            child: Text(
              ['🎥', '✍️', '🎤'][index % 3],
              style: const TextStyle(fontSize: 32),
            ),
          ),
          // Overlay stats
          Positioned(
            bottom: 4,
            left: 4,
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye_outlined,
                    color: GColors.textPrimary, size: 12),
                const SizedBox(width: 2),
                Text(
                  '${(index + 1) * 123}',
                  style: GTextStyle.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

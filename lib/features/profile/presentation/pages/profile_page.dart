import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/animations/haptic_service.dart';
import '../../../../core/services/cloudflare_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/content_model.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  final String? userId; // null = mon profil

  const ProfilePage({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProfile = ref.watch(myProfileProvider);
    final isMyProfile = userId == null;
    final resolvedUserId = userId ?? myProfile?.id;

    // Pas encore connecté ou profil non chargé
    if (resolvedUserId == null) {
      return const Scaffold(
        backgroundColor: GColors.void_,
        body: Center(child: CircularProgressIndicator(color: GColors.orange)),
      );
    }

    // Charger le profil si c'est un profil externe
    final profileAsync = isMyProfile && myProfile != null
        ? AsyncValue.data(myProfile)
        : ref.watch(profileProvider(resolvedUserId));

    // Contenus de l'utilisateur
    final contentsAsync = ref.watch(userContentsProvider(resolvedUserId));

    // Compteurs en temps réel
    final countersAsync = ref.watch(profileCountersProvider(resolvedUserId));

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: GColors.void_,
        body: Center(child: CircularProgressIndicator(color: GColors.orange)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: GColors.void_,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_off_outlined,
                color: GColors.textTertiary,
                size: 48,
              ),
              const SizedBox(height: GSpacing.md),
              Text('Profil introuvable',
                  style: GTextStyle.bodyLarge
                      .copyWith(color: GColors.textSecondary)),
              const SizedBox(height: GSpacing.lg),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: GSpacing.lg, vertical: GSpacing.sm),
                  decoration: BoxDecoration(
                    color: GColors.surface,
                    borderRadius: BorderRadius.circular(GRadius.full),
                    border: Border.all(color: GColors.border),
                  ),
                  child: Text(
                    'Retour',
                    style: GTextStyle.labelMedium
                        .copyWith(color: GColors.orange),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (user) => _ProfileContent(
        user: user,
        isMyProfile: isMyProfile,
        contentsAsync: contentsAsync,
        countersAsync: countersAsync,
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final UserModel user;
  final bool isMyProfile;
  final AsyncValue<List<ContentModel>> contentsAsync;
  final AsyncValue<Map<String, int>> countersAsync;

  const _ProfileContent({
    required this.user,
    required this.isMyProfile,
    required this.contentsAsync,
    required this.countersAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followState = isMyProfile
        ? null
        : ref.watch(followProvider(user.id));

    // Compteurs : préférer les données temps réel, fallback sur user
    final followers = countersAsync.valueOrNull?['followers']
        ?? user.followersCount;
    final following = countersAsync.valueOrNull?['following']
        ?? user.followingCount;
    final posts = countersAsync.valueOrNull?['posts'] ?? user.postsCount;

    return Scaffold(
      backgroundColor: GColors.void_,
      body: CustomScrollView(
        slivers: [
          // ── Header avec bannière ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: GColors.void_,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Bannière
                  user.bannerUrl != null
                      ? CachedNetworkImage(
                          imageUrl: user.bannerUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _DefaultBanner(level: user.level),
                        )
                      : _DefaultBanner(level: user.level),

                  // Gradient bas
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, GColors.void_],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),

                  // Avatar + nom
                  Positioned(
                    bottom: GSpacing.lg,
                    left: GSpacing.xl,
                    right: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: GColors.orange, width: 2.5),
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: GColors.surface,
                            backgroundImage: user.avatarUrl != null
                                ? CachedNetworkImageProvider(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? const Icon(
                                    Icons.person_outline_rounded,
                                    color: GColors.textTertiary,
                                    size: 30,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: GSpacing.md),

                        // Nom + badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.displayName,
                                      style: GTextStyle.headlineSmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: GSpacing.xs),
                                  Text(
                                    UserLevel.fromString(user.level).emoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  if (user.isVerified)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(Icons.verified,
                                          color: GColors.info, size: 16),
                                    ),
                                ],
                              ),
                              Text(
                                '@${user.username}',
                                style: GTextStyle.bodySmall.copyWith(
                                    color: GColors.textSecondary),
                              ),
                            ],
                          ),
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
                Padding(
                  padding: const EdgeInsets.only(right: GSpacing.md),
                  child: _FollowButton(
                    followState: followState,
                    onTap: () {
                      GHaptics.medium();
                      ref.read(followProvider(user.id).notifier).toggle();
                    },
                  ),
                ),
            ],
          ),

          // ── Bio ──────────────────────────────────────────────────────
          if (user.bio != null && user.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: GSpacing.xl, vertical: GSpacing.md),
                child: Text(user.bio!, style: GTextStyle.bodyMedium),
              ).animate().fadeIn(),
            ),

          // ── Stats ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: GSpacing.xl, vertical: GSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(label: 'Posts', value: posts),
                  _Stat(label: 'Abonnés', value: followers),
                  _Stat(label: 'Abonnements', value: following),
                ],
              ).animate().fadeIn(delay: 100.ms),
            ),
          ),

          const SliverToBoxAdapter(child: Divider(color: GColors.border)),

          // ── Grille de contenus ──────────────────────────────────────────
          contentsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(GSpacing.xl),
                child: Center(
                    child: CircularProgressIndicator(color: GColors.orange)),
              ),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(GSpacing.xl),
                child: Center(
                    child: Text('Erreur de chargement',
                        style: TextStyle(color: GColors.textSecondary))),
              ),
            ),
            data: (contents) => contents.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(GSpacing.xxl),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: GColors.surface,
                                borderRadius:
                                    BorderRadius.circular(GRadius.xl),
                                border: Border.all(
                                    color: GColors.border, width: 0.5),
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                color: GColors.textTertiary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: GSpacing.md),
                            Text(
                              isMyProfile
                                  ? 'Aucune publication pour l\'instant'
                                  : 'Aucune publication',
                              style: GTextStyle.bodyMedium.copyWith(
                                  color: GColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: GSpacing.sm),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: contents.length,
                      itemBuilder: (_, i) {
                        final item = contents[i];
                        return _ContentGridItem(content: item)
                            .animate(
                                delay:
                                    Duration(milliseconds: i * 20))
                            .fadeIn()
                            .scale(begin: const Offset(0.9, 0.9));
                      },
                    ),
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Follow button ────────────────────────────────────────────────────────────

class _FollowButton extends StatelessWidget {
  final AsyncValue<bool>? followState;
  final VoidCallback onTap;

  const _FollowButton({required this.followState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (followState == null) return const SizedBox.shrink();

    return followState!.when(
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: GColors.orange),
      ),
      error: (_, __) => _button(false),
      data: (isFollowing) => _button(isFollowing),
    );
  }

  Widget _button(bool isFollowing) {
    return AnimatedContainer(
      duration: 200.ms,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFollowing ? GColors.surface : GColors.orange,
          foregroundColor:
              isFollowing ? GColors.textPrimary : Colors.white,
          minimumSize: const Size(80, 36),
          padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
          side: isFollowing
              ? const BorderSide(color: GColors.border)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GRadius.full),
          ),
        ),
        child: Text(isFollowing ? 'Suivi ✓' : 'Suivre'),
      ),
    );
  }
}

// ── Widgets helpers ──────────────────────────────────────────────────────────

class _DefaultBanner extends StatelessWidget {
  final String level;
  const _DefaultBanner({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'legende' => GColors.gold,
      'grand_patron' => GColors.orange,
      'influenceur' => const Color(0xFF7C3AED),
      _ => GColors.surface,
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.4), GColors.void_],
        ),
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
          style:
              GTextStyle.headlineMedium.copyWith(color: GColors.textPrimary),
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
  final ContentModel content;
  const _ContentGridItem({required this.content});

  @override
  Widget build(BuildContext context) {
    // Résoudre la thumbnail
    final thumb = content.thumbnailUrl ??
        CloudflareService.thumbnailUrl(content.streamId);

    return GestureDetector(
      onTap: () => context.push('/content/${content.id}'),
      child: Container(
        color: GColors.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail ou emoji placeholder
            if (thumb != null)
              CachedNetworkImage(
                imageUrl: thumb,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _TypeEmoji(content.type),
              )
            else
              _TypeEmoji(content.type),

            // Overlay type + stats
            Positioned(
              bottom: 4,
              left: 4,
              child: Row(
                children: [
                  Icon(
                    _typeIcon(content.type),
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formatCount(content.viewsCount),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 4),
                        ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(ContentType type) => switch (type) {
        ContentType.video => Icons.play_circle_outline,
        ContentType.text => Icons.text_fields,
        ContentType.audio => Icons.mic_none,
      };

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _TypeEmoji extends StatelessWidget {
  final ContentType type;
  const _TypeEmoji(this.type);

  @override
  Widget build(BuildContext context) {
    final emoji = switch (type) {
      ContentType.video => '🎥',
      ContentType.text => '✍️',
      ContentType.audio => '🎤',
    };
    return Center(child: Text(emoji, style: const TextStyle(fontSize: 32)));
  }
}

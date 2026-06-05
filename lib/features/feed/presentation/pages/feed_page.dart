import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../shared/models/content_model.dart';
import '../providers/feed_provider.dart';
import '../widgets/video_content_card.dart';
import '../widgets/text_content_card.dart';
import '../widgets/audio_content_card.dart';
import '../widgets/skeleton_feed.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with AutomaticKeepAliveClientMixin {
  final _pageController = PageController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: GColors.void_,
      body: Stack(
        children: [
          // ── Feed principal ──────────────────────────────────────────
          _FeedContent(pageController: _pageController),

          // ── Header (tabs Pour Toi / Abonnements) ────────────────────
          SafeArea(
            child: _FeedHeader(),
          ),
        ],
      ),
    );
  }
}

class _FeedHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(feedTabProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TabButton(
            label: '🔥 Pour Toi',
            isActive: currentTab == FeedTab.forYou,
            onTap: () {
              ref.read(feedTabProvider.notifier).state = FeedTab.forYou;
            },
          ),
          const SizedBox(width: GSpacing.lg),
          _TabButton(
            label: '👥 Abonnements',
            isActive: currentTab == FeedTab.following,
            onTap: () {
              ref.read(feedTabProvider.notifier).state = FeedTab.following;
            },
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedDefaultTextStyle(
        duration: GDuration.fast,
        style: isActive
            ? GTextStyle.labelLarge.copyWith(
                color: GColors.textPrimary,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(color: GColors.orangeGlow, blurRadius: 10),
                ],
              )
            : GTextStyle.labelMedium.copyWith(
                color: GColors.textTertiary,
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: GDuration.fast,
              width: isActive ? 30 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: GColors.orange,
                borderRadius: BorderRadius.circular(GRadius.full),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedContent extends ConsumerStatefulWidget {
  final PageController pageController;
  const _FeedContent({required this.pageController});

  @override
  ConsumerState<_FeedContent> createState() => _FeedContentState();
}

class _FeedContentState extends ConsumerState<_FeedContent> {
  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(feedTabProvider);
    final feedState = currentTab == FeedTab.forYou
        ? ref.watch(forYouFeedProvider)
        : ref.watch(followingFeedProvider);
    final controller = currentTab == FeedTab.forYou
        ? ref.read(forYouFeedProvider.notifier)
        : ref.read(followingFeedProvider.notifier);

    if (feedState.isLoading) {
      return const SkeletonFeed();
    }

    if (feedState.error != null && feedState.items.isEmpty) {
      return _ErrorFeed(onRetry: () => controller.load());
    }

    if (feedState.items.isEmpty) {
      return const _EmptyFeed();
    }

    return PageView.builder(
      controller: widget.pageController,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: feedState.items.length + (feedState.hasMore ? 1 : 0),
      onPageChanged: (index) {
        controller.updateCurrentIndex(index);
      },
      itemBuilder: (context, index) {
        if (index >= feedState.items.length) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(GColors.orange),
            ),
          );
        }

        final content = feedState.items[index];
        return _ContentCard(
          content: content,
          isActive: index == feedState.currentIndex,
          onReact: (type) => controller.react(content.id, type),
        );
      },
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentModel content;
  final bool isActive;
  final ValueChanged<String> onReact;

  const _ContentCard({
    required this.content,
    required this.isActive,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return switch (content.type) {
      ContentType.video => VideoContentCard(
          content: content,
          isActive: isActive,
          onReact: onReact,
        ),
      ContentType.text => TextContentCard(
          content: content,
          isActive: isActive,
          onReact: onReact,
        ),
      ContentType.audio => AudioContentCard(
          content: content,
          isActive: isActive,
          onReact: onReact,
        ),
    };
  }
}

class _ErrorFeed extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorFeed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GColors.surface,
              borderRadius: BorderRadius.circular(GRadius.xl),
              border: Border.all(color: GColors.border, width: 0.5),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: GColors.textTertiary,
              size: 28,
            ),
          ),
          const SizedBox(height: GSpacing.lg),
          Text(
            'Impossible de charger',
            style: GTextStyle.headlineSmall,
          ),
          const SizedBox(height: GSpacing.sm),
          Text(
            'Vérifie ta connexion',
            style: GTextStyle.bodyMedium.copyWith(
              color: GColors.textSecondary,
            ),
          ),
          const SizedBox(height: GSpacing.xl),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: GSpacing.xl,
                vertical: GSpacing.md,
              ),
              decoration: BoxDecoration(
                color: GColors.orange,
                borderRadius: BorderRadius.circular(GRadius.lg),
              ),
              child: Text(
                'Réessayer',
                style: GTextStyle.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GColors.surface,
              borderRadius: BorderRadius.circular(GRadius.xl),
              border: Border.all(color: GColors.border, width: 0.5),
            ),
            child: const Icon(
              Icons.local_fire_department_outlined,
              color: GColors.orange,
              size: 28,
            ),
          ),
          const SizedBox(height: GSpacing.lg),
          Text(
            'Aucun Gbairai pour l\'instant',
            style: GTextStyle.headlineSmall,
          ),
          const SizedBox(height: GSpacing.sm),
          Text(
            'Sois le premier à publier',
            style: GTextStyle.bodyMedium.copyWith(
              color: GColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/glassmorphism.dart';
import '../../../../core/services/cloudflare_service.dart';
import '../../../../shared/models/content_model.dart';
import '../providers/trends_provider.dart';
import '../../data/repositories/trends_datasource.dart';

class TrendsPage extends ConsumerStatefulWidget {
  const TrendsPage({super.key});

  @override
  ConsumerState<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends ConsumerState<TrendsPage>
    with AutomaticKeepAliveClientMixin {
  String _selectedFilter = 'Tous';

  static const _filters = ['Tous', 'Humour', 'Sport', 'Music', 'People', 'Food'];
  static const _periods = <String, String>{
    'Dernière heure': 'hour',
    'Aujourd\'hui': 'day',
    'Cette semaine': 'week',
  };

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: GColors.void_,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: GColors.void_,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tendances', style: GTextStyle.headlineMedium),
                  Consumer(
                    builder: (_, ref, __) {
                      final activeAsync = ref.watch(activeUsersProvider);
                      final count = activeAsync.valueOrNull ?? 0;
                      return Text(
                        count > 0
                            ? '$count Gbairais actifs maintenant'
                            : 'Gbairais actifs maintenant',
                        style: GTextStyle.bodySmall.copyWith(
                          color: GColors.orange,
                        ),
                      );
                    },
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(
                left: GSpacing.md,
                bottom: GSpacing.sm,
              ),
            ),
          ),

          // ── Filtres ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                _HorizontalFilter(
                  items: _filters,
                  selected: _selectedFilter,
                  onSelect: (f) => setState(() => _selectedFilter = f),
                ),
                const SizedBox(height: GSpacing.sm),
                Consumer(
                  builder: (_, ref, __) {
                    final period = ref.watch(trendsPeriodProvider);
                    final periodLabel = _periods.entries
                        .firstWhere((e) => e.value == period,
                            orElse: () =>
                                const MapEntry('Aujourd\'hui', 'day'))
                        .key;
                    return _HorizontalFilter(
                      items: _periods.keys.toList(),
                      selected: periodLabel,
                      onSelect: (label) {
                        final value = _periods[label] ?? 'day';
                        ref.read(trendsPeriodProvider.notifier).state = value;
                      },
                      isSmall: true,
                    );
                  },
                ),
                const SizedBox(height: GSpacing.lg),
              ],
            ),
          ),

          // ── Gbairai du moment ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Gbairai du moment', emoji: '👑'),
                  const SizedBox(height: GSpacing.md),
                  Consumer(
                    builder: (_, ref, __) {
                      final period = ref.watch(trendsPeriodProvider);
                      final contentsAsync = ref.watch(topContentProvider(period));
                      return contentsAsync.when(
                        loading: () => const _FeaturedPlaceholder(),
                        error: (_, __) => const _FeaturedPlaceholder(),
                        data: (contents) => contents.isEmpty
                            ? const _FeaturedPlaceholder()
                            : _FeaturedContent(content: contents.first),
                      );
                    },
                  ),
                  const SizedBox(height: GSpacing.xl),
                ],
              ),
            ),
          ),

          // ── Top 20 ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
              child: _SectionTitle(title: 'Top 20 en ascension', emoji: '📈'),
            ),
          ),

          Consumer(
            builder: (_, ref, __) {
              final period = ref.watch(trendsPeriodProvider);
              final contentsAsync = ref.watch(topContentProvider(period));
              return contentsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(GSpacing.xl),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: GColors.orange)),
                  ),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(GSpacing.xl),
                    child: Center(
                      child: Text('Erreur de chargement',
                          style: GTextStyle.bodySmall
                              .copyWith(color: GColors.textSecondary)),
                    ),
                  ),
                ),
                data: (contents) => SliverList.builder(
                  itemCount: contents.length,
                  itemBuilder: (_, i) => _RankingItem(
                    rank: i + 1,
                    content: contents[i],
                  )
                      .animate(delay: Duration(milliseconds: i * 30))
                      .fadeIn()
                      .slideX(begin: 0.1),
                ),
              );
            },
          ),

          // ── Hashtags ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(GSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: GSpacing.md),
                  _SectionTitle(title: 'Hashtags du moment', emoji: '#'),
                  const SizedBox(height: GSpacing.md),
                  Consumer(
                    builder: (_, ref, __) {
                      final hashAsync = ref.watch(trendingHashtagsProvider);
                      return hashAsync.when(
                        loading: () => const CircularProgressIndicator(
                            color: GColors.orange),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (hashtags) => Wrap(
                          spacing: GSpacing.sm,
                          runSpacing: GSpacing.sm,
                          children: hashtags
                              .asMap()
                              .entries
                              .map((e) => _HashtagChip(
                                    rank: e.key + 1,
                                    hashtag: e.value,
                                  ))
                              .toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalFilter extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool isSmall;

  const _HorizontalFilter({
    required this.items,
    required this.selected,
    required this.onSelect,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isSmall ? 32 : 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final isActive = item == selected;
          return GestureDetector(
            onTap: () => onSelect(item),
            child: AnimatedContainer(
              duration: GDuration.fast,
              margin: const EdgeInsets.only(right: GSpacing.sm),
              padding: EdgeInsets.symmetric(
                horizontal: GSpacing.md,
                vertical: isSmall ? GSpacing.xs : GSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isActive ? GColors.orange : GColors.surface,
                borderRadius: BorderRadius.circular(GRadius.full),
                border: Border.all(
                  color: isActive ? GColors.orange : GColors.border,
                ),
              ),
              child: Text(
                item,
                style: (isSmall ? GTextStyle.labelSmall : GTextStyle.labelMedium)
                    .copyWith(
                  color: isActive ? GColors.textPrimary : GColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String emoji;

  const _SectionTitle({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: GSpacing.sm),
        Text(title, style: GTextStyle.headlineSmall),
      ],
    );
  }
}

class _FeaturedPlaceholder extends StatelessWidget {
  const _FeaturedPlaceholder();
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      height: 200,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GColors.red.withValues(alpha: 0.4),
              GColors.orange.withValues(alpha: 0.2)
            ],
          ),
          borderRadius: BorderRadius.circular(GRadius.lg),
        ),
        child: const Center(
          child: Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }
}

class _FeaturedContent extends StatelessWidget {
  final ContentModel content;
  const _FeaturedContent({required this.content});

  @override
  Widget build(BuildContext context) {
    final thumb = content.thumbnailUrl ??
        CloudflareService.thumbnailUrl(content.streamId);

    return GestureDetector(
      onTap: () => context.push('/content/${content.id}'),
      child: GlassCard(
        padding: EdgeInsets.zero,
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail ou gradient
            ClipRRect(
              borderRadius: BorderRadius.circular(GRadius.lg),
              child: thumb != null
                  ? CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _defaultBg(),
                    )
                  : _defaultBg(),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, GColors.void_.withValues(alpha: 0.9)],
                ),
                borderRadius: BorderRadius.circular(GRadius.lg),
              ),
            ),

            // Infos
            Positioned(
              bottom: GSpacing.md,
              left: GSpacing.md,
              right: GSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.caption?.isNotEmpty == true
                        ? content.caption!
                        : '${_formatCount(content.viewsCount)} vues',
                    style: GTextStyle.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (content.authorUsername != null)
                        Text(
                          '@${content.authorUsername}',
                          style: GTextStyle.bodySmall
                              .copyWith(color: GColors.textSecondary),
                        ),
                      const Spacer(),
                      _LevelBadge(level: content.gbairaiLevel),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultBg() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GColors.red.withValues(alpha: 0.4),
              GColors.orange.withValues(alpha: 0.2)
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
      );

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _LevelBadge extends StatelessWidget {
  final GbairaiLevel? level;
  const _LevelBadge({this.level});

  @override
  Widget build(BuildContext context) {
    if (level == null) return const SizedBox.shrink();
    final (label, color) = switch (level!) {
      GbairaiLevel.legendaire => ('👑 LÉGENDE', GColors.gold),
      GbairaiLevel.national => ('🚨 NATIONAL', GColors.red),
      GbairaiLevel.local => ('📍 LOCAL', GColors.orange),
      _ => ('🌱 ÉMERGENT', GColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(GRadius.full),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(label,
          style: GTextStyle.labelSmall.copyWith(color: color)),
    );
  }
}

class _RankingItem extends StatelessWidget {
  final int rank;
  final ContentModel content;
  const _RankingItem({required this.rank, required this.content});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    const medals = ['🥇', '🥈', '🥉'];
    final thumb = content.thumbnailUrl ??
        CloudflareService.thumbnailUrl(content.streamId);

    return GestureDetector(
      onTap: () => context.push('/content/${content.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: GSpacing.md, vertical: GSpacing.xs),
        padding: const EdgeInsets.all(GSpacing.md),
        decoration: BoxDecoration(
          color: isTop3
              ? GColors.orange.withValues(alpha: 0.08)
              : GColors.surface,
          borderRadius: BorderRadius.circular(GRadius.md),
          border: Border.all(
            color: isTop3
                ? GColors.orange.withValues(alpha: 0.3)
                : GColors.border,
          ),
        ),
        child: Row(
          children: [
            // Rang
            SizedBox(
              width: 40,
              child: Text(
                isTop3 ? medals[rank - 1] : '#$rank',
                style: isTop3
                    ? const TextStyle(fontSize: 20)
                    : GTextStyle.labelLarge
                        .copyWith(color: GColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: GSpacing.md),

            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(GRadius.sm),
              child: thumb != null
                  ? CachedNetworkImage(
                      imageUrl: thumb,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _typeEmoji(content.type),
                    )
                  : _typeEmoji(content.type),
            ),
            const SizedBox(width: GSpacing.sm),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.caption?.isNotEmpty == true
                        ? content.caption!
                        : _typeLabel(content.type),
                    style: GTextStyle.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_fmt(content.viewsCount)} vues'
                    '${content.authorUsername != null ? ' · @${content.authorUsername}' : ''}',
                    style: GTextStyle.bodySmall,
                  ),
                ],
              ),
            ),

            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmt(content.reactionsCount),
                  style: GTextStyle.labelSmall
                      .copyWith(color: GColors.success),
                ),
                const Icon(Icons.trending_up,
                    color: GColors.success, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeEmoji(ContentType type) {
    final emoji = switch (type) {
      ContentType.video => '🎥',
      ContentType.text => '✍️',
      ContentType.audio => '🎤',
    };
    return Container(
      width: 40,
      height: 40,
      color: GColors.elevated,
      child: Center(child: Text(emoji)),
    );
  }

  String _typeLabel(ContentType type) => switch (type) {
        ContentType.video => 'Vidéo',
        ContentType.text => 'Statut',
        ContentType.audio => 'Vocal',
      };

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _HashtagChip extends StatelessWidget {
  final int rank;
  final TrendHashtag hashtag;
  const _HashtagChip({required this.rank, required this.hashtag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO Phase 4 : naviguer vers la page hashtag
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.md, vertical: GSpacing.sm),
        decoration: BoxDecoration(
          color: GColors.surface,
          borderRadius: BorderRadius.circular(GRadius.full),
          border: Border.all(color: GColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('#${hashtag.tag}', style: GTextStyle.labelMedium),
            const SizedBox(width: GSpacing.xs),
            Text(
              _fmt(hashtag.usesLastDay),
              style: GTextStyle.labelSmall.copyWith(color: GColors.orange),
            ),
            const SizedBox(width: GSpacing.xs),
            const Icon(Icons.arrow_upward,
                color: GColors.orange, size: 12),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

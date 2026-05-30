import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/glassmorphism.dart';

class TrendsPage extends ConsumerStatefulWidget {
  const TrendsPage({super.key});

  @override
  ConsumerState<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends ConsumerState<TrendsPage>
    with AutomaticKeepAliveClientMixin {
  String _selectedFilter = 'Tous';
  String _selectedPeriod = 'Aujourd\'hui';

  static const _filters = ['Tous', 'Humour', 'Sport', 'Music', 'People', 'Food'];
  static const _periods = ['Dernière heure', 'Aujourd\'hui', 'Cette semaine'];

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
                  Text(
                    '🔥 Tendances',
                    style: GTextStyle.headlineMedium,
                  ),
                  Text(
                    '247 Gbairais actifs maintenant',
                    style: GTextStyle.bodySmall.copyWith(
                      color: GColors.orange,
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(
                left: GSpacing.md,
                bottom: GSpacing.sm,
              ),
            ),
          ),

          // ── Filtres catégories ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                _HorizontalFilter(
                  items: _filters,
                  selected: _selectedFilter,
                  onSelect: (f) => setState(() => _selectedFilter = f),
                ),
                const SizedBox(height: GSpacing.sm),
                _HorizontalFilter(
                  items: _periods,
                  selected: _selectedPeriod,
                  onSelect: (p) => setState(() => _selectedPeriod = p),
                  isSmall: true,
                ),
                const SizedBox(height: GSpacing.lg),
              ],
            ),
          ),

          // ── Gbairai du moment (grand format) ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Gbairai du moment', emoji: '👑'),
                  const SizedBox(height: GSpacing.md),
                  _FeaturedContent(),
                  const SizedBox(height: GSpacing.xl),
                ],
              ),
            ),
          ),

          // ── Top 20 en ascension ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Top 20 en ascension', emoji: '📈'),
                  const SizedBox(height: GSpacing.md),
                ],
              ),
            ),
          ),

          SliverList.builder(
            itemCount: 20,
            itemBuilder: (_, i) => _RankingItem(rank: i + 1)
                .animate(delay: Duration(milliseconds: i * 30))
                .fadeIn()
                .slideX(begin: 0.1),
          ),

          // ── Hashtags du moment ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(GSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: GSpacing.md),
                  _SectionTitle(title: 'Hashtags du moment', emoji: '#'),
                  const SizedBox(height: GSpacing.md),
                  Wrap(
                    spacing: GSpacing.sm,
                    runSpacing: GSpacing.sm,
                    children: List.generate(15, (i) => _HashtagChip(rank: i + 1)),
                  ),
                  const SizedBox(height: 100), // Padding bottom nav
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

class _FeaturedContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      height: 200,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [GColors.red.withValues(alpha: 0.4), GColors.orange.withValues(alpha: 0.2)],
              ),
              borderRadius: BorderRadius.circular(GRadius.lg),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 60)),
            ),
          ),
          Positioned(
            bottom: GSpacing.md,
            left: GSpacing.md,
            right: GSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vidéo du moment — 42K vues',
                  style: GTextStyle.headlineSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GColors.red.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(GRadius.full),
                        border: Border.all(color: GColors.red, width: 0.5),
                      ),
                      child: Text(
                        '🚨 NATIONAL',
                        style: GTextStyle.labelSmall.copyWith(color: GColors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingItem extends StatelessWidget {
  final int rank;
  const _RankingItem({required this.rank});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final medals = ['🥇', '🥈', '🥉'];

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: GSpacing.md,
        vertical: GSpacing.xs,
      ),
      padding: const EdgeInsets.all(GSpacing.md),
      decoration: BoxDecoration(
        color: isTop3
            ? GColors.orange.withValues(alpha: 0.08)
            : GColors.surface,
        borderRadius: BorderRadius.circular(GRadius.md),
        border: Border.all(
          color: isTop3 ? GColors.orange.withValues(alpha: 0.3) : GColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              isTop3 ? medals[rank - 1] : '#$rank',
              style: isTop3
                  ? const TextStyle(fontSize: 20)
                  : GTextStyle.labelLarge.copyWith(
                      color: GColors.textTertiary,
                    ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: GSpacing.md),
          CircleAvatar(
            radius: 20,
            backgroundColor: GColors.elevated,
            child: const Text('📸', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: GSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contenu #$rank', style: GTextStyle.labelLarge),
                Text(
                  '${(rank * 1234).toString()} vues · @auteur$rank',
                  style: GTextStyle.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${rank % 5 > 2 ? rank * 12 : ''}',
                style: GTextStyle.labelSmall.copyWith(color: GColors.success),
              ),
              const Icon(Icons.trending_up, color: GColors.success, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final int rank;
  const _HashtagChip({required this.rank});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GSpacing.md,
          vertical: GSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: GColors.surface,
          borderRadius: BorderRadius.circular(GRadius.full),
          border: Border.all(color: GColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#Gbairai$rank',
              style: GTextStyle.labelMedium,
            ),
            const SizedBox(width: GSpacing.xs),
            Text(
              '${rank * 234}',
              style: GTextStyle.labelSmall.copyWith(color: GColors.orange),
            ),
            const SizedBox(width: GSpacing.xs),
            const Icon(Icons.arrow_upward, color: GColors.orange, size: 12),
          ],
        ),
      ),
    );
  }
}

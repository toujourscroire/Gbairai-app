import 'package:flutter/material.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../shared/models/content_model.dart';
import '../../../../shared/models/user_model.dart';

class ContentInfoRow extends StatelessWidget {
  final ContentModel content;

  const ContentInfoRow({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Auteur ────────────────────────────────────────────────────
        Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: GColors.surface,
              backgroundImage: content.authorAvatarUrl != null
                  ? NetworkImage(content.authorAvatarUrl!)
                  : null,
              child: content.authorAvatarUrl == null
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: GColors.textTertiary,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: GSpacing.sm),

            // Nom + badge
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          content.isAnonymous
                              ? (content.anonUsername ?? 'Anonyme')
                              : (content.authorDisplayName ?? content.authorUsername ?? ''),
                          style: GTextStyle.labelLarge.copyWith(
                            shadows: [const Shadow(color: Colors.black, blurRadius: 8)],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!content.isAnonymous && content.authorLevel != null) ...[
                        const SizedBox(width: GSpacing.xs),
                        _LevelBadge(level: content.authorLevel!),
                      ],
                      if (content.isAnonymous) ...[
                        const SizedBox(width: GSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: GColors.surface,
                            borderRadius: BorderRadius.circular(GRadius.full),
                          ),
                          child: Text(
                            '#Anonyme',
                            style: GTextStyle.labelSmall.copyWith(
                              color: GColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (content.city.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📍 ${content.district ?? content.city}',
                      style: GTextStyle.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: GSpacing.sm),

        // ── Caption ───────────────────────────────────────────────────
        if (content.caption != null && content.type != ContentType.text) ...[
          Text(
            content.caption!,
            style: GTextStyle.bodyMedium.copyWith(
              shadows: [const Shadow(color: Colors.black, blurRadius: 8)],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: GSpacing.xs),
        ],

        // ── Gbairai level badge ────────────────────────────────────────
        if (content.gbairaiLevel != null)
          _GbairaiLevelBadge(level: content.gbairaiLevel!),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final userLevel = UserLevel.fromString(level);
    return Text(userLevel.emoji, style: const TextStyle(fontSize: 14));
  }
}

class _GbairaiLevelBadge extends StatelessWidget {
  final GbairaiLevel level;
  const _GbairaiLevelBadge({required this.level});

  String get _badge => switch (level) {
    GbairaiLevel.preGbairai => '🔥 Chauffe',
    GbairaiLevel.local => '🔥🔥 Local',
    GbairaiLevel.national => '🚨 NATIONAL',
    GbairaiLevel.legendaire => '👑 LÉGENDAIRE',
  };

  Color get _color => switch (level) {
    GbairaiLevel.preGbairai => GColors.orange,
    GbairaiLevel.local => GColors.orange,
    GbairaiLevel.national => GColors.red,
    GbairaiLevel.legendaire => GColors.gold,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(GRadius.full),
        border: Border.all(color: _color, width: 0.5),
      ),
      child: Text(
        _badge,
        style: GTextStyle.labelSmall.copyWith(color: _color),
      ),
    );
  }
}

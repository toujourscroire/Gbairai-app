import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/animations/haptic_service.dart';
import '../../../../shared/models/content_model.dart';
import 'animated_counter.dart';

// 6 réactions ivoiriennes
const _reactions = [
  ('gbairai',    '🔥', 'Gbairai !'),
  ('on_a_ri',   '😂', 'On a ri'),
  ('cest_vrai', '😱', 'C\'est vrai ?'),
  ('wari_deh',  '💰', 'Wari dèh'),
  ('dja',       '🤌', 'Dja !'),
  ('we_we',     '😤', 'Wê wê'),
];

class ContentActionsColumn extends StatefulWidget {
  final ContentModel content;
  final ValueChanged<String> onReact;
  final VoidCallback? onComment;
  final VoidCallback? onVoiceReact;
  final VoidCallback? onShare;

  const ContentActionsColumn({
    super.key,
    required this.content,
    required this.onReact,
    this.onComment,
    this.onVoiceReact,
    this.onShare,
  });

  @override
  State<ContentActionsColumn> createState() => _ContentActionsColumnState();
}

class _ContentActionsColumnState extends State<ContentActionsColumn> {
  bool _showReactionPicker = false;
  String? _flyingEmoji;

  void _triggerEmojiAnimation(String emoji) {
    setState(() => _flyingEmoji = emoji);
    Future.delayed(GDuration.verySlow, () {
      if (mounted) setState(() => _flyingEmoji = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final myReaction = widget.content.myReaction;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Réaction principale ────────────────────────────────────
            _ActionButton(
              icon: myReaction != null
                  ? _reactions
                      .firstWhere(
                        (r) => r.$1 == myReaction,
                        orElse: () => _reactions.first,
                      )
                      .$2
                  : '🔥',
              label: widget.content.reactionsCount,
              isActive: myReaction != null,
              onTap: () {
                GHaptics.reaction();
                setState(() => _showReactionPicker = !_showReactionPicker);
              },
              onLongPress: () {
                GHaptics.reaction();
                setState(() => _showReactionPicker = true);
              },
            ),

            const SizedBox(height: GSpacing.lg),

            // ── Commentaires ──────────────────────────────────────────
            _ActionButton(
              icon: '💬',
              label: widget.content.commentsCount,
              onTap: () {
                GHaptics.light();
                widget.onComment?.call();
              },
            ),

            const SizedBox(height: GSpacing.lg),

            // ── Réaction vocale ────────────────────────────────────────
            _ActionButton(
              icon: '🎤',
              label: widget.content.voiceReactionsCount,
              onTap: () {
                GHaptics.medium();
                widget.onVoiceReact?.call();
              },
            ),

            const SizedBox(height: GSpacing.lg),

            // ── Partage WhatsApp ───────────────────────────────────────
            _ActionButton(
              icon: '📤',
              label: widget.content.sharesCount,
              onTap: () {
                GHaptics.light();
                widget.onShare?.call();
              },
            ),
          ],
        ),

        // ── Picker réactions (popup) ───────────────────────────────────
        if (_showReactionPicker)
          Positioned(
            right: 56,
            top: 0,
            child: _ReactionPicker(
              currentReaction: widget.content.myReaction,
              onSelect: (type, emoji) {
                setState(() => _showReactionPicker = false);
                widget.onReact(type);
                _triggerEmojiAnimation(emoji);
              },
              onDismiss: () => setState(() => _showReactionPicker = false),
            ),
          ),

        // ── Emoji volant (animation post-réaction) ─────────────────────
        if (_flyingEmoji != null)
          Positioned(
            right: 8,
            child: Text(_flyingEmoji!, style: const TextStyle(fontSize: 40))
                .animate()
                .moveY(end: -200, duration: GDuration.verySlow, curve: Curves.easeOut)
                .fadeOut(delay: Duration(milliseconds: GDuration.verySlow.inMilliseconds ~/ 2)),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final int label;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          AnimatedContainer(
            duration: GDuration.fast,
            curve: Curves.elasticOut,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? GColors.orange.withValues(alpha: 0.2)
                  : GColors.glassBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? GColors.orange : GColors.glassBorder,
              ),
              boxShadow: isActive ? GShadow.orangeGlow : null,
            ),
            child: Center(
              child: AnimatedScale(
                scale: isActive ? 1.2 : 1.0,
                duration: GDuration.fast,
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          CompactCounter(
            count: label,
            color: isActive ? GColors.orange : GColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ReactionPicker extends StatelessWidget {
  final String? currentReaction;
  final void Function(String type, String emoji) onSelect;
  final VoidCallback onDismiss;

  const _ReactionPicker({
    required this.currentReaction,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.all(GSpacing.sm),
        decoration: BoxDecoration(
          color: GColors.glassBg,
          borderRadius: BorderRadius.circular(GRadius.xxl),
          border: Border.all(color: GColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _reactions.map((r) {
            final (type, emoji, label) = r;
            final isSelected = currentReaction == type;
            return GestureDetector(
              onTap: () {
                GHaptics.reaction();
                onSelect(type, emoji);
              },
              child: AnimatedContainer(
                duration: GDuration.fast,
                width: 44,
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? GColors.orange.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(GRadius.md),
                ),
                child: Tooltip(
                  message: label,
                  child: Center(
                    child: AnimatedScale(
                      scale: isSelected ? 1.3 : 1.0,
                      duration: GDuration.fast,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ).animate().scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/animations/haptic_service.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../../../shared/models/content_model.dart';

/// Bottom sheet des commentaires d'un contenu.
///
/// Usage :
///   showModalBottomSheet(
///     context: context,
///     isScrollControlled: true,
///     backgroundColor: Colors.transparent,
///     builder: (_) => CommentSheet(contentId: '...'),
///   );
class CommentSheet extends ConsumerStatefulWidget {
  final String contentId;
  const CommentSheet({super.key, required this.contentId});

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final _datasource = FeedRemoteDatasource();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<CommentModel> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await _datasource.getComments(widget.contentId);
      if (mounted) setState(() { _comments = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    await GHaptics.medium();
    try {
      await _datasource.addComment(
        contentId: widget.contentId,
        body: text,
      );
      _controller.clear();
      _focusNode.unfocus();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: GColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: GColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(GRadius.xl)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────────
          const SizedBox(height: GSpacing.md),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: GColors.border,
                borderRadius: BorderRadius.circular(GRadius.full),
              ),
            ),
          ),
          const SizedBox(height: GSpacing.md),

          // ── Titre ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
            child: Row(
              children: [
                Text('Commentaires', style: GTextStyle.headlineSmall),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GColors.orange,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: GSpacing.md),

          // ── Liste ────────────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _buildList(),
          ),

          const Divider(color: GColors.border, height: 1),

          // ── Champ de saisie ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GSpacing.md, GSpacing.sm, GSpacing.md, GSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: GColors.elevated,
                      borderRadius: BorderRadius.circular(GRadius.full),
                      border: Border.all(color: GColors.border),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: GTextStyle.bodyMedium,
                      maxLines: 1,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText: 'Ajoute un commentaire…',
                        hintStyle: GTextStyle.bodyMedium.copyWith(
                          color: GColors.textTertiary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: GSpacing.md,
                          vertical: GSpacing.sm,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: GSpacing.sm),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: GColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(GSpacing.xl),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: GColors.orange,
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(GSpacing.xl),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: GColors.textTertiary, size: 32),
              const SizedBox(height: GSpacing.md),
              Text(
                'Impossible de charger',
                style: GTextStyle.bodyMedium.copyWith(
                  color: GColors.textSecondary,
                ),
              ),
              const SizedBox(height: GSpacing.md),
              GestureDetector(
                onTap: () {
                  setState(() { _loading = true; _error = null; });
                  _load();
                },
                child: Text(
                  'Réessayer',
                  style: GTextStyle.labelMedium.copyWith(color: GColors.orange),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(GSpacing.xl),
          child: Text(
            'Aucun commentaire — sois le premier !',
            style: GTextStyle.bodyMedium.copyWith(
              color: GColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
      itemCount: _comments.length,
      itemBuilder: (_, i) => _CommentTile(comment: _comments[i])
          .animate()
          .fadeIn(delay: Duration(milliseconds: i * 40)),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: GColors.elevated,
            backgroundImage: comment.authorAvatarUrl != null
                ? NetworkImage(comment.authorAvatarUrl!)
                : null,
            child: comment.authorAvatarUrl == null
                ? Text(
                    (comment.authorUsername ?? '?')[0].toUpperCase(),
                    style: GTextStyle.labelSmall.copyWith(
                      color: GColors.orange,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: GSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorUsername ?? 'Anonyme',
                  style: GTextStyle.labelSmall.copyWith(
                    color: GColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.body,
                  style: GTextStyle.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

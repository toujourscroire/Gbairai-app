import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/services/supabase_service.dart';
import '../providers/notifications_provider.dart';
import '../../data/notifications_datasource.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseService.isReady) {
      return const Scaffold(
        backgroundColor: GColors.void_,
        body: Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: GColors.orange)),
      );
    }

    final notifState = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: GColors.void_,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  GSpacing.xl, GSpacing.md, GSpacing.md, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Activité', style: GTextStyle.headlineLarge),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(notificationsProvider.notifier)
                        .markAllAsRead(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: GSpacing.md, vertical: GSpacing.sm),
                    ),
                    child: Text(
                      'Tout lire',
                      style: GTextStyle.labelMedium
                          .copyWith(color: GColors.orange),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: GSpacing.md),

            // ── Contenu ──────────────────────────────────────────────────
            Expanded(
              child: notifState.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: GColors.orange),
                  ),
                ),
                error: (e, _) => _ErrorState(
                  onRetry: () =>
                      ref.read(notificationsProvider.notifier).refresh(),
                ),
                data: (notifications) => notifications.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        color: GColors.orange,
                        backgroundColor: GColors.surface,
                        onRefresh: () =>
                            ref.read(notificationsProvider.notifier).refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: GSpacing.xl),
                          itemCount: notifications.length,
                          itemBuilder: (_, i) {
                            final notif = notifications[i];
                            return _NotificationTile(
                              notification: notif,
                              onTap: () {
                                ref
                                    .read(notificationsProvider.notifier)
                                    .markAsRead(notif.id);
                                if (notif.deepLink != null) {
                                  context.push(notif.deepLink!);
                                }
                              },
                            )
                                .animate(
                                    delay: Duration(milliseconds: i * 25))
                                .fadeIn(duration: 300.ms)
                                .slideY(
                                  begin: 0.08,
                                  duration: 300.ms,
                                  curve: Curves.easeOutCubic,
                                );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile de notification ──────────────────────────────────────────────────────

class _NotificationTile extends StatefulWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final notif = widget.notification;
    final isUnread = !notif.isRead;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: GDuration.ultraFast,
        margin: const EdgeInsets.only(bottom: GSpacing.sm),
        padding: const EdgeInsets.all(GSpacing.md),
        decoration: BoxDecoration(
          color: _pressed
              ? GColors.elevated
              : isUnread
                  ? GColors.surface
                  : GColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(GRadius.lg),
          border: Border.all(
            color: isUnread
                ? GColors.border
                : GColors.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône de type
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: GColors.elevated,
                    borderRadius: BorderRadius.circular(GRadius.md),
                  ),
                  child: Icon(
                    _typeIcon(notif.type),
                    color: _typeColor(notif.type),
                    size: 18,
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: GColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: GSpacing.md),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: GTextStyle.labelLarge.copyWith(
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif.body,
                    style: GTextStyle.bodySmall.copyWith(
                      color: GColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: GSpacing.sm),

            // Temps
            if (notif.createdAt != null)
              Text(
                notif.createdAt!.timeAgo,
                style: GTextStyle.bodySmall.copyWith(
                  color: GColors.textTertiary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) => switch (type) {
        'alert' => Icons.warning_amber_rounded,
        'reaction' => Icons.local_fire_department_rounded,
        'comment' => Icons.chat_bubble_outline_rounded,
        'follow' => Icons.person_add_outlined,
        'mention' => Icons.alternate_email_rounded,
        'voice_reaction' => Icons.mic_outlined,
        _ => Icons.notifications_outlined,
      };

  Color _typeColor(String type) => switch (type) {
        'alert' => GColors.error,
        'reaction' => GColors.orange,
        'comment' => GColors.info,
        'follow' => GColors.success,
        'mention' => GColors.gold,
        'voice_reaction' => const Color(0xFFA855F7),
        _ => GColors.textSecondary,
      };
}

// ── États vide / erreur ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.notifications_outlined,
              color: GColors.textTertiary,
              size: 28,
            ),
          ),
          const SizedBox(height: GSpacing.lg),
          Text(
            'Aucune notification',
            style: GTextStyle.headlineSmall,
          ),
          const SizedBox(height: GSpacing.sm),
          Text(
            'Les réactions, commentaires et\nnouvelles activités apparaîtront ici',
            textAlign: TextAlign.center,
            style: GTextStyle.bodyMedium.copyWith(
              color: GColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: GColors.textTertiary,
            size: 40,
          ),
          const SizedBox(height: GSpacing.md),
          Text(
            'Problème de chargement',
            style:
                GTextStyle.bodyLarge.copyWith(color: GColors.textSecondary),
          ),
          const SizedBox(height: GSpacing.lg),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: GSpacing.lg, vertical: GSpacing.sm),
              decoration: BoxDecoration(
                color: GColors.surface,
                borderRadius: BorderRadius.circular(GRadius.full),
                border: Border.all(color: GColors.border),
              ),
              child: Text(
                'Réessayer',
                style:
                    GTextStyle.labelMedium.copyWith(color: GColors.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

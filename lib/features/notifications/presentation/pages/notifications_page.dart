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
            child: CircularProgressIndicator(color: GColors.orange)),
      );
    }

    final notifState = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: GColors.void_,
      appBar: AppBar(
        title: const Text('Activité'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllAsRead(),
            child: Text(
              'Tout lire',
              style:
                  GTextStyle.labelMedium.copyWith(color: GColors.orange),
            ),
          ),
        ],
      ),
      body: notifState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: GColors.orange)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: GSpacing.md),
              Text('Erreur de chargement',
                  style: GTextStyle.bodyMedium
                      .copyWith(color: GColors.textSecondary)),
              const SizedBox(height: GSpacing.lg),
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: const Text('Réessayer',
                    style: TextStyle(color: GColors.orange)),
              ),
            ],
          ),
        ),
        data: (notifications) => notifications.isEmpty
            ? _EmptyNotifications()
            : RefreshIndicator(
                color: GColors.orange,
                onRefresh: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: GSpacing.md),
                  itemCount: notifications.length,
                  itemBuilder: (_, i) {
                    final notif = notifications[i];
                    return _NotificationItem(
                      notification: notif,
                      onTap: () {
                        // Marquer comme lu
                        ref
                            .read(notificationsProvider.notifier)
                            .markAsRead(notif.id);
                        // Navigation si deep link
                        if (notif.deepLink != null) {
                          context.push(notif.deepLink!);
                        }
                      },
                    )
                        .animate(
                            delay: Duration(milliseconds: i * 30))
                        .fadeIn()
                        .slideX(begin: 0.05);
                  },
                ),
              ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = _typeEmoji(notification.type);
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: GSpacing.sm),
        padding: const EdgeInsets.all(GSpacing.md),
        decoration: BoxDecoration(
          color: isUnread
              ? GColors.orange.withValues(alpha: 0.05)
              : GColors.surface,
          borderRadius: BorderRadius.circular(GRadius.lg),
          border: Border.all(
            color: isUnread
                ? GColors.orange.withValues(alpha: 0.2)
                : GColors.border,
          ),
        ),
        child: Row(
          children: [
            // Icône + badge
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: GColors.elevated,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: GColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: GSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title,
                      style: GTextStyle.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: GTextStyle.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            if (notification.createdAt != null)
              Text(
                notification.createdAt!.timeAgo,
                style: GTextStyle.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  String _typeEmoji(String type) => switch (type) {
        'alert' => '🚨',
        'reaction' => '🔥',
        'comment' => '💬',
        'follow' => '👤',
        'mention' => '@',
        'voice_reaction' => '🎤',
        _ => '🔔',
      };
}

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔔', style: TextStyle(fontSize: 64)),
          const SizedBox(height: GSpacing.md),
          Text(
            'Aucune notification',
            style: GTextStyle.headlineSmall,
          ),
          const SizedBox(height: GSpacing.sm),
          Text(
            'Les réactions, commentaires et abonnés\napparaîtront ici',
            textAlign: TextAlign.center,
            style: GTextStyle.bodyMedium
                .copyWith(color: GColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

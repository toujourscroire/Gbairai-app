import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design/design_tokens.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.void_,
      appBar: AppBar(
        title: const Text('Activité'),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Tout lire',
              style: GTextStyle.labelMedium.copyWith(color: GColors.orange),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
        itemCount: 20,
        itemBuilder: (_, i) => _NotificationItem(index: i)
            .animate(delay: Duration(milliseconds: i * 30))
            .fadeIn()
            .slideX(begin: 0.05),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final int index;
  const _NotificationItem({required this.index});

  @override
  Widget build(BuildContext context) {
    final types = [
      ('🚨', 'Alerte Gbairai', 'Yopougon brûle — 8K vues en 1h'),
      ('🔥', 'Nouvelle réaction', '@Konan a réagi à ton Gbairai'),
      ('💬', 'Commentaire', '@Aya : "Dja trop ça !"'),
      ('👤', 'Nouvel abonné', '@Serge te suit maintenant'),
    ];
    final (emoji, title, body) = types[index % 4];
    final isUnread = index < 3;

    return Container(
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
          // Emoji + badge non lu
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: GColors.elevated,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
                Text(title, style: GTextStyle.labelLarge),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GTextStyle.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Text(
            DateTime.now()
                .subtract(Duration(minutes: index * 17))
                .timeAgo,
            style: GTextStyle.bodySmall,
          ),
        ],
      ),
    );
  }
}

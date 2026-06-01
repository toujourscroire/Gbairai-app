import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String? deepLink;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.deepLink,
    this.createdAt,
    this.data = const {},
  });
}

class NotificationsDatasource {
  SupabaseClient get _client => SupabaseService.client;

  // ── Charger les notifications (paginé) ───────────────────────────
  Future<List<NotificationItem>> fetchNotifications({
    int offset = 0,
    int limit = 30,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final result = await _client
        .from('notifications')
        .select('id, type, title, body, is_read, deep_link, data, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (result as List).map(_mapItem).toList();
  }

  // ── Stream temps réel des nouvelles notifs ───────────────────────
  Stream<List<NotificationItem>> notificationsStream() {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((rows) => rows.map(_mapItem).toList());
  }

  // ── Marquer une notification comme lue ───────────────────────────
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // ── Marquer toutes les notifs comme lues ─────────────────────────
  Future<void> markAllAsRead() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // ── Compter les non-lues ─────────────────────────────────────────
  Future<int> unreadCount() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return 0;

    final result = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false)
        .count(CountOption.exact);

    return result.count;
  }

  // ── Helper mapping ────────────────────────────────────────────────
  NotificationItem _mapItem(Map<String, dynamic> row) {
    return NotificationItem(
      id: row['id'] as String,
      type: row['type'] as String,
      title: row['title'] as String,
      body: row['body'] as String,
      isRead: row['is_read'] as bool? ?? false,
      deepLink: row['deep_link'] as String?,
      data: (row['data'] as Map<String, dynamic>?) ?? {},
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? ''),
    );
  }
}

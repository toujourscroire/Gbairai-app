import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications_datasource.dart';
import '../../../../core/services/supabase_service.dart';

final notificationsDatasourceProvider = Provider<NotificationsDatasource>(
  (_) => NotificationsDatasource(),
);

// ── Stream des notifications (temps réel) ────────────────────────────────────

final notificationsStreamProvider =
    StreamProvider<List<NotificationItem>>((ref) {
  if (!SupabaseService.isReady) return const Stream.empty();
  return ref.watch(notificationsDatasourceProvider).notificationsStream();
});

// ── Compteur de non-lues ─────────────────────────────────────────────────────

final unreadCountProvider = FutureProvider<int>((ref) {
  if (!SupabaseService.isReady) return Future.value(0);
  return ref.watch(notificationsDatasourceProvider).unreadCount();
});

// ── Actions ──────────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  NotificationsNotifier(this._datasource)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final NotificationsDatasource _datasource;

  Future<void> _load() async {
    try {
      final items = await _datasource.fetchNotifications();
      state = AsyncValue.data(items);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> markAsRead(String id) async {
    await _datasource.markAsRead(id);
    // Mise à jour locale optimiste
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current
          .map((n) => n.id == id
              ? NotificationItem(
                  id: n.id,
                  type: n.type,
                  title: n.title,
                  body: n.body,
                  isRead: true,
                  deepLink: n.deepLink,
                  createdAt: n.createdAt,
                  data: n.data,
                )
              : n)
          .toList(),
    );
  }

  Future<void> markAllAsRead() async {
    await _datasource.markAllAsRead();
    await _load();
  }

  Future<void> refresh() => _load();
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationItem>>>(
  (ref) => NotificationsNotifier(ref.watch(notificationsDatasourceProvider)),
);

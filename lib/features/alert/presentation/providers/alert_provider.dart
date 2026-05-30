import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/design/animations/haptic_service.dart';
import '../../../../shared/models/alert_model.dart';

// Stream temps réel des alertes Gbairai
final alertStreamProvider = StreamProvider<AlertModel?>((ref) {
  final client = SupabaseService.client;

  return client
      .from('gbairai_alerts')
      .stream(primaryKey: ['id'])
      .order('triggered_at', ascending: false)
      .limit(1)
      .map((data) {
        if (data.isEmpty) return null;
        final item = data.first;
        return AlertModel(
          id: item['id'] as String,
          contentId: item['content_id'] as String,
          level: AlertLevel.fromString(item['level'] as String),
          titleGenerated: item['title_generated'] as String,
          triggeredAt: DateTime.parse(item['triggered_at'] as String),
          sentCount: item['sent_count'] as int? ?? 0,
          openedCount: item['opened_count'] as int? ?? 0,
          openRate: (item['open_rate'] as num?)?.toDouble(),
          isSponsored: item['is_sponsored'] as bool? ?? false,
          cityScope: item['city_scope'] as String?,
        );
      });
});

// Provider pour savoir si une alerte doit s'afficher
final shouldShowAlertProvider = StateProvider<bool>((ref) => false);
final currentAlertProvider = StateProvider<AlertModel?>((ref) => null);

// Live view counter (Realtime) pour un contenu spécifique
final liveViewCountProvider =
    StreamProvider.family<int, String>((ref, contentId) {
  return SupabaseService.client
      .from('contents')
      .stream(primaryKey: ['id'])
      .eq('id', contentId)
      .map((data) => data.isEmpty ? 0 : (data.first['views_count'] as int? ?? 0));
});

// Live réactions en streaming
final liveReactionsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, contentId) {
  return SupabaseService.client
      .from('reactions')
      .stream(primaryKey: ['id'])
      .eq('content_id', contentId)
      .order('created_at', ascending: false)
      .limit(20)
      .map((data) => data
          .map((r) => {
                'type': r['reaction_type'] as String,
                'user_id': r['user_id'] as String,
              })
          .toList());
});

// Contrôleur d'alerte
class AlertNotifier extends StateNotifier<AlertModel?> {
  AlertNotifier() : super(null);

  Future<void> showAlert(AlertModel alert) async {
    state = alert;
    await GHaptics.gbairaiAlert();
    await AnalyticsService.alertOpened(alert.level.value);
  }

  void dismiss() => state = null;
}

final alertControllerProvider =
    StateNotifierProvider<AlertNotifier, AlertModel?>((ref) {
  return AlertNotifier();
});

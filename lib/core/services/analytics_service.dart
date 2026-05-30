import 'package:posthog_flutter/posthog_flutter.dart';
import '../constants/app_constants.dart';

// PostHog analytics — RGPD compliant
// Jamais de données personnelles identifiables
abstract final class AnalyticsService {
  static Future<void> initialize() async {
    final config = PostHogConfig(AppConstants.posthogApiKey);
    config.host = AppConstants.posthogHost;
    config.captureApplicationLifecycleEvents = true;
    config.debug = !AppConstants.isProduction;
    config.sendFeatureFlagEvent = false;
    config.captureScreenViews = false;
    await Posthog().setup(config);
  }

  static Future<void> identify(String userId) async {
    // Uniquement l'ID, pas d'email/téléphone
    await Posthog().identify(userId: userId);
  }

  static Future<void> reset() async {
    await Posthog().reset();
  }

  // ── Events métier ─────────────────────────────────────────────────
  static Future<void> track(
    String event, {
    Map<String, dynamic>? properties,
  }) async {
    await Posthog().capture(
      eventName: event,
      properties: _sanitizeProperties(properties),
    );
  }

  static Future<void> screen(String screenName) async {
    await Posthog().screen(screenName: screenName);
  }

  // ── Events prédéfinis ─────────────────────────────────────────────
  static Future<void> contentPublished(String type) async =>
      track('content_published', properties: {'type': type});

  static Future<void> reactionSent(String reactionType) async =>
      track('reaction_sent', properties: {'type': reactionType});

  static Future<void> alertOpened(String level) async =>
      track('alert_opened', properties: {'level': level});

  static Future<void> contentShared(String platform) async =>
      track('content_shared', properties: {'platform': platform});

  static Future<void> authCompleted(String method) async =>
      track('auth_completed', properties: {'method': method});

  // Purger les propriétés sensibles avant envoi
  static Map<String, dynamic>? _sanitizeProperties(
    Map<String, dynamic>? props,
  ) {
    if (props == null) return null;
    final sanitized = Map<String, dynamic>.from(props);
    // Supprimer tout ce qui ressemble à des données personnelles
    for (final key in ['phone', 'email', 'name', 'username', 'password']) {
      sanitized.remove(key);
    }
    return sanitized;
  }
}

import 'package:posthog_flutter/posthog_flutter.dart';
import '../constants/app_constants.dart';

abstract final class AnalyticsService {
  static Future<void> initialize() async {
    final config = PostHogConfig(AppConstants.posthogApiKey);
    config.host = AppConstants.posthogHost;
    config.captureApplicationLifecycleEvents = true;
    config.debug = !AppConstants.isProduction;
    await Posthog().setup(config);
  }

  static Future<void> identify(String userId) async {
    await Posthog().identify(userId: userId);
  }

  static Future<void> reset() async {
    await Posthog().reset();
  }

  static Future<void> track(
    String event, {
    Map<String, Object>? properties,
  }) async {
    await Posthog().capture(
      eventName: event,
      properties: properties,
    );
  }

  static Future<void> screen(String screenName) async {
    await Posthog().screen(screenName: screenName);
  }

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
}

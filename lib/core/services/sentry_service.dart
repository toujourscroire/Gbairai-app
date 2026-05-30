// Sentry temporairement désactivé — bug Swift dans sentry_flutter avec Xcode latest
// (SentryBinaryImageCache.image removed in sentry-cocoa).
// À réactiver dès que le plugin est patché (>8.14.x).
// Les erreurs sont capturées via PostHog en attendant.

abstract final class SentryService {
  static Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? extras,
  }) async {
    // no-op
  }

  static Future<void> captureSecurityEvent(
    String event, {
    Map<String, dynamic>? context,
  }) async {
    // no-op
  }

  static void setUser(String userId) {}
  static void clearUser() {}
}

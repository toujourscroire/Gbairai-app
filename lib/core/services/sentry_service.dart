import 'package:sentry_flutter/sentry_flutter.dart';
import '../constants/app_constants.dart';

abstract final class SentryService {
  // Capturer une erreur avec contexte
  static Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? extras,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (!AppConstants.isProduction) return; // Pas de bruit en dev

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.level = level;
        if (extras != null) {
          extras.forEach((key, value) {
            scope.setExtra(key, value);
          });
        }
      },
    );
  }

  // Capturer un message d'audit sécurité
  static Future<void> captureSecurityEvent(
    String event, {
    Map<String, dynamic>? context,
  }) async {
    await Sentry.captureMessage(
      '[SECURITY] $event',
      level: SentryLevel.warning,
      withScope: (scope) {
        scope.setTag('type', 'security');
        if (context != null) {
          context.forEach((k, v) => scope.setExtra(k, v));
        }
      },
    );
  }

  // Identifier l'utilisateur (anonymisé — pas de PII)
  static void setUser(String userId) {
    Sentry.configureScope((scope) {
      // Uniquement l'ID hashé, jamais le numéro ou l'email
      scope.setUser(SentryUser(id: userId));
    });
  }

  static void clearUser() {
    Sentry.configureScope((scope) => scope.setUser(null));
  }
}

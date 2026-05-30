import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/services/supabase_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/analytics_service.dart';
import 'core/constants/app_constants.dart';
import 'app.dart';

Future<void> bootstrap() async {
  // 1. Sentry — erreurs capturées dès le démarrage
  await SentryFlutter.init(
    (options) {
      options.dsn = AppConstants.sentryDsn;
      options.environment = AppConstants.environment;
      options.tracesSampleRate = AppConstants.isProduction ? 0.2 : 1.0;
      options.attachScreenshot = true;
      options.sendDefaultPii = false; // RGPD — pas de PII auto
    },
    appRunner: () async {
      // 2. Supabase
      await SupabaseService.initialize();

      // 3. Firebase + FCM
      await FcmService.initialize();

      // 4. Analytics
      await AnalyticsService.initialize();

      // 5. Lancement app dans ProviderScope Riverpod
      runApp(
        const ProviderScope(
          child: GbairaiApp(),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'core/services/supabase_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/analytics_service.dart';
import 'app.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

Future<void> bootstrap() async {
  // 1. Supabase — timeout 15s (requis par AuthController)
  try {
    await SupabaseService.initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _log.w('[Bootstrap] Supabase init timeout (15s) — continuing');
      },
    );
  } catch (e, st) {
    _log.e('[Bootstrap] Supabase init failed', error: e, stackTrace: st);
  }

  // 2. Firebase + FCM — timeout 10s
  try {
    await FcmService.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _log.w('[Bootstrap] FCM init timeout (10s) — continuing');
      },
    );
  } catch (e, st) {
    _log.e('[Bootstrap] Firebase/FCM init failed', error: e, stackTrace: st);
  }

  // 3. Analytics (PostHog) — timeout 8s
  try {
    await AnalyticsService.initialize().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _log.w('[Bootstrap] Analytics init timeout (8s) — continuing');
      },
    );
  } catch (e, st) {
    _log.e('[Bootstrap] Analytics init failed', error: e, stackTrace: st);
  }

  // 4. Lancement app — UN SEUL runApp, après les services
  runApp(
    const ProviderScope(
      child: GbairaiApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'core/services/supabase_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/analytics_service.dart';
import 'app.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

Future<void> bootstrap() async {
  // 1. Supabase
  try {
    await SupabaseService.initialize();
  } catch (e, st) {
    _log.e('[Bootstrap] Supabase init failed', error: e, stackTrace: st);
  }

  // 2. Firebase + FCM
  try {
    await FcmService.initialize();
  } catch (e, st) {
    _log.e('[Bootstrap] Firebase/FCM init failed', error: e, stackTrace: st);
  }

  // 3. Analytics (PostHog)
  try {
    await AnalyticsService.initialize();
  } catch (e, st) {
    _log.e('[Bootstrap] Analytics init failed', error: e, stackTrace: st);
  }

  // 4. Lancement app dans ProviderScope Riverpod
  runApp(
    const ProviderScope(
      child: GbairaiApp(),
    ),
  );
}

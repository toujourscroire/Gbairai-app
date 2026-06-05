import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'core/services/supabase_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/analytics_service.dart';
import 'app.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

Future<void> bootstrap() async {
  debugPrint('[BOOTSTRAP] start');

  // ── Supabase d'abord — critique pour AuthController ─────────────────
  debugPrint('[BOOTSTRAP] Supabase initialize...');
  try {
    await SupabaseService.initialize().timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        debugPrint('[BOOTSTRAP] Supabase init TIMEOUT (6s) — continuing without Supabase');
        _log.w('[Bootstrap] Supabase init timeout (6s) — continuing without Supabase');
      },
    );
    debugPrint('[BOOTSTRAP] Supabase OK — isReady=${SupabaseService.isReady}');
  } catch (e, st) {
    debugPrint('[BOOTSTRAP] Supabase FAILED: $e');
    _log.e('[Bootstrap] Supabase init failed', error: e, stackTrace: st);
  }

  debugPrint('[BOOTSTRAP] isReady=${SupabaseService.isReady}');

  // ── Lancement app IMMÉDIATEMENT après Supabase ───────────────────────
  debugPrint('[BOOTSTRAP] calling runApp()...');
  runApp(
    const ProviderScope(
      child: GbairaiApp(),
    ),
  );
  debugPrint('[BOOTSTRAP] runApp() called');

  // ── Firebase + FCM — non bloquant, en arrière-plan ───────────────────
  try {
    await FcmService.initialize().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _log.w('[Bootstrap] FCM init timeout (8s) — FCM désactivé');
      },
    );
  } catch (e, st) {
    _log.e('[Bootstrap] Firebase/FCM init failed', error: e, stackTrace: st);
  }

  // ── Analytics (PostHog) — non bloquant ───────────────────────────────
  try {
    await AnalyticsService.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _log.w('[Bootstrap] Analytics init timeout (5s) — continuing');
      },
    );
  } catch (e, st) {
    _log.e('[Bootstrap] Analytics init failed', error: e, stackTrace: st);
  }
}

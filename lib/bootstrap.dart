import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'core/services/supabase_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/analytics_service.dart';
import 'app.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

Future<void> bootstrap() async {
  // ── BOOT 1 — Flutter est initialisé (appelé depuis main.dart) ────────────
  debugPrint('[BOOT 1] Flutter initialized — starting bootstrap');

  // ── BOOT 2 — runApp() EN PREMIER : évite l'écran noir ────────────────────
  // runApp() DOIT être appelé avant tout await réseau.
  // Les services s'initialisent en background via _initServicesAsync().
  debugPrint('[BOOT 2] runApp() called — ProviderScope mounting');
  runApp(
    const ProviderScope(
      child: GbairaiApp(),
    ),
  );
  debugPrint('[BOOT 2] runApp() returned — widget tree is rendering');

  // ── BOOT 3 — Supabase (bloquant car requis par AuthController) ─────────────
  debugPrint('[BOOT 3] Supabase initialization starting...');
  try {
    await SupabaseService.initialize();
    debugPrint('[BOOT 3] Supabase initialized ✓');
  } catch (e, st) {
    _log.e('[BOOT 3] Supabase init FAILED', error: e, stackTrace: st);
    debugPrint('[BOOT 3] Supabase init failed: $e');
  }

  // ── BOOT 4 — Firebase/FCM (non bloquant pour le UI) ───────────────────────
  debugPrint('[BOOT 4] Firebase/FCM initialization starting...');
  try {
    await FcmService.initialize()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('[BOOT 4] Firebase/FCM init TIMEOUT (10s) — continuing');
          },
        );
    debugPrint('[BOOT 4] Firebase/FCM initialized ✓');
  } catch (e, st) {
    _log.e('[BOOT 4] Firebase/FCM init failed', error: e, stackTrace: st);
    debugPrint('[BOOT 4] Firebase/FCM init failed: $e');
  }

  // ── BOOT 5 — Analytics PostHog (non bloquant — lancé en fire-and-forget) ──
  // PostHog.setup() fait un appel réseau iOS. NE PAS await avant runApp().
  // Ici on est déjà après runApp() — on peut await mais avec timeout.
  debugPrint('[BOOT 5] Analytics initialization starting...');
  try {
    await AnalyticsService.initialize()
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('[BOOT 5] Analytics init TIMEOUT (8s) — PostHog désactivé');
          },
        );
    debugPrint('[BOOT 5] Analytics initialized ✓');
  } catch (e, st) {
    _log.e('[BOOT 5] Analytics init failed', error: e, stackTrace: st);
    debugPrint('[BOOT 5] Analytics init failed: $e');
  }

  debugPrint('[BOOT] Bootstrap complete — app running');
}

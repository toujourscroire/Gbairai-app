import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'core/services/supabase_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/analytics_service.dart';
import 'diag/boot_diagnostics.dart';
import 'app.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

Future<void> bootstrap() async {
  bootLog('BOOT 1 — bootstrap() démarré');

  // ── BOOT 2 — Premier runApp : BootDiagnosticApp visible immédiatement ─────
  runApp(const BootDiagnosticApp());
  bootLog('BOOT 2 — BootDiagnosticApp lancée (écran visible)');

  // ── BOOT 3 — Supabase (timeout 15s) ──────────────────────────────────────
  bootLog('BOOT 3 — Supabase.initialize() démarré...');
  try {
    await SupabaseService.initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        bootLog('BOOT 3 TIMEOUT — Supabase dépassé 15s, on continue');
      },
    );
    bootLog('BOOT 3 OK — Supabase initialisé');
  } catch (e, st) {
    _log.e('[BOOT 3] Supabase init FAILED', error: e, stackTrace: st);
    bootLog('BOOT 3 ERREUR — ${e.toString().substring(0, e.toString().length.clamp(0, 80))}');
  }

  // ── BOOT 4 — Firebase/FCM (timeout 10s) ───────────────────────────────────
  bootLog('BOOT 4 — Firebase/FCM initialize() démarré...');
  try {
    await FcmService.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        bootLog('BOOT 4 TIMEOUT — Firebase dépassé 10s, on continue');
      },
    );
    bootLog('BOOT 4 OK — Firebase initialisé');
  } catch (e, st) {
    _log.e('[BOOT 4] Firebase/FCM init failed', error: e, stackTrace: st);
    bootLog('BOOT 4 ERREUR — ${e.toString().substring(0, e.toString().length.clamp(0, 80))}');
  }

  // ── BOOT 5 — PostHog Analytics (timeout 8s) ───────────────────────────────
  bootLog('BOOT 5 — PostHog initialize() démarré...');
  try {
    await AnalyticsService.initialize().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        bootLog('BOOT 5 TIMEOUT — PostHog dépassé 8s, on continue');
      },
    );
    bootLog('BOOT 5 OK — PostHog initialisé');
  } catch (e, st) {
    _log.e('[BOOT 5] Analytics init failed', error: e, stackTrace: st);
    bootLog('BOOT 5 ERREUR — ${e.toString().substring(0, e.toString().length.clamp(0, 80))}');
  }

  // ── BOOT 6 — Second runApp : GbairaiApp + overlay permanent ──────────────
  // L'overlay est SIBLING de ProviderScope(GbairaiApp()) dans le Stack racine.
  // Si GbairaiApp crashe (exception provider, router, theme) → écran noir SOUS
  // l'overlay, qui reste visible et affiche le dernier BOOT atteint.
  bootLog('BOOT 6 — runApp(GbairaiApp) appelé...');
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: const [
          ProviderScope(child: GbairaiApp()),
          BootOverlay(),
        ],
      ),
    ),
  );
  bootLog('BOOT 6 OK — ProviderScope + overlay montés');
}

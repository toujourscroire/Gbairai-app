// Rate Limiter côté client
// OWASP M4 — Insecure Authentication / API Abuse mitigation

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum RateLimitAction {
  publish,
  reaction,
  comment,
  report,
  authAttempt,
  otp,
}

class RateLimiter {
  static RateLimiter? _instance;
  static RateLimiter get instance => _instance ??= RateLimiter._();
  RateLimiter._();

  // Limites par action (count, fenêtre en secondes)
  static const Map<RateLimitAction, ({int count, int windowSeconds})> _limits = {
    RateLimitAction.publish:     (count: 10, windowSeconds: 3600),   // 10/h
    RateLimitAction.reaction:    (count: 30, windowSeconds: 60),     // 30/min
    RateLimitAction.comment:     (count: 50, windowSeconds: 3600),   // 50/h
    RateLimitAction.report:      (count: 20, windowSeconds: 86400),  // 20/j
    RateLimitAction.authAttempt: (count: 5,  windowSeconds: 900),    // 5/15min
    RateLimitAction.otp:         (count: 3,  windowSeconds: 600),    // 3/10min
  };

  // Vérifie et enregistre une action
  Future<RateLimitResult> checkAndRecord(RateLimitAction action) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'rl_${action.name}';
    final limit = _limits[action]!;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Récupérer historique des timestamps
    final raw = prefs.getString(key);
    List<int> timestamps = raw != null
        ? List<int>.from(json.decode(raw) as List<dynamic>)
        : [];

    // Nettoyer les timestamps hors fenêtre
    final windowStart = now - limit.windowSeconds;
    timestamps = timestamps.where((t) => t > windowStart).toList();

    if (timestamps.length >= limit.count) {
      final oldestInWindow = timestamps.first;
      final retryAfter = oldestInWindow + limit.windowSeconds - now;
      return RateLimitResult(
        allowed: false,
        retryAfterSeconds: retryAfter,
        remaining: 0,
      );
    }

    // Enregistrer l'action
    timestamps.add(now);
    await prefs.setString(key, json.encode(timestamps));

    return RateLimitResult(
      allowed: true,
      remaining: limit.count - timestamps.length,
      retryAfterSeconds: 0,
    );
  }

  // Réinitialiser une action (ex: après déconnexion)
  Future<void> reset(RateLimitAction action) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rl_${action.name}');
  }
}

class RateLimitResult {
  final bool allowed;
  final int remaining;
  final int retryAfterSeconds;

  const RateLimitResult({
    required this.allowed,
    required this.remaining,
    required this.retryAfterSeconds,
  });

  String get retryAfterMessage {
    if (retryAfterSeconds < 60) return 'Réessaie dans ${retryAfterSeconds}s';
    if (retryAfterSeconds < 3600) {
      return 'Réessaie dans ${retryAfterSeconds ~/ 60} min';
    }
    return 'Réessaie dans ${retryAfterSeconds ~/ 3600}h';
  }
}

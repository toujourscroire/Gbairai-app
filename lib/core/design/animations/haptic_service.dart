import 'package:flutter/services.dart';

abstract final class GHaptics {
  // Réaction légère (tap, navigation)
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  // Réaction medium (validation, toggle)
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  // Réaction forte (alerte, erreur)
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  // Succès (publication, follow)
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  // Erreur (validation échouée)
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.mediumImpact();
  }

  // Alerte Gbairai (pattern signature — 3 pulses)
  static Future<void> gbairaiAlert() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  // Réaction emoji (double-tap)
  static Future<void> reaction() async {
    await HapticFeedback.mediumImpact();
  }

  // OTP digit entry
  static Future<void> digit() async {
    await HapticFeedback.selectionClick();
  }
}

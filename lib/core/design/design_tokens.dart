import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════════
// GBAIRAI DESIGN TOKENS — Source unique de vérité pour le design system
// ════════════════════════════════════════════════════════════════════

abstract final class GColors {
  // ── Fondation ────────────────────────────────────────────────────
  static const void_ = Color(0xFF080810);
  static const black = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A2E);
  static const elevated = Color(0xFF252540);
  static const border = Color(0xFF2E2E4A);

  // ── Accentuation ─────────────────────────────────────────────────
  static const orange = Color(0xFFE85D04);
  static const red = Color(0xFFDC2626);
  static const gold = Color(0xFFF5A623);
  static const green = Color(0xFF16A34A); // WhatsApp / succès

  // ── Glows ────────────────────────────────────────────────────────
  static const orangeGlow = Color(0x40E85D04); // 25%
  static const redGlow = Color(0x33DC2626);    // 20%
  static const goldGlow = Color(0x33F5A623);   // 20%

  // ── Texte ────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF2F2F7);
  static const textSecondary = Color(0xFF8E8EAD);
  static const textTertiary = Color(0xFF4A4A6A);
  static const textInverse = Color(0xFF0D0D0D);

  // ── Glassmorphism ─────────────────────────────────────────────────
  static const glassBg = Color(0xB81A1A2E);      // rgba(26,26,46,0.72)
  static const glassBorder = Color(0x12FFFFFF);   // rgba(255,255,255,0.07)
  static const glassShine = Color(0x08FFFFFF);    // rgba(255,255,255,0.03)

  // ── Overlay sombre (pour vidéos) ──────────────────────────────────
  static const videoOverlay = Color(0xCC000000);  // 80%
  static const videoGradientTop = Color(0x660D0D0D);
  static const videoGradientBottom = Color(0xE60D0D0D);

  // ── États ────────────────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
}

abstract final class GSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

abstract final class GRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 999.0;
}

abstract final class GFont {
  static const String sora = 'Sora';
  static const String inter = 'Inter';
}

abstract final class GTextStyle {
  // Headlines — Sora
  static const displayLarge = TextStyle(
    fontFamily: GFont.sora,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: GColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.1,
  );
  static const displayMedium = TextStyle(
    fontFamily: GFont.sora,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: GColors.textPrimary,
    letterSpacing: -0.8,
    height: 1.15,
  );
  static const displaySmall = TextStyle(
    fontFamily: GFont.sora,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: GColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const headlineLarge = TextStyle(
    fontFamily: GFont.sora,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: GColors.textPrimary,
    height: 1.3,
  );
  static const headlineMedium = TextStyle(
    fontFamily: GFont.sora,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: GColors.textPrimary,
    height: 1.3,
  );
  static const headlineSmall = TextStyle(
    fontFamily: GFont.sora,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: GColors.textPrimary,
    height: 1.35,
  );

  // Corps — Inter
  static const bodyLarge = TextStyle(
    fontFamily: GFont.inter,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: GColors.textPrimary,
    height: 1.5,
  );
  static const bodyMedium = TextStyle(
    fontFamily: GFont.inter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: GColors.textPrimary,
    height: 1.5,
  );
  static const bodySmall = TextStyle(
    fontFamily: GFont.inter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: GColors.textSecondary,
    height: 1.5,
  );

  // Labels — Inter Medium
  static const labelLarge = TextStyle(
    fontFamily: GFont.inter,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: GColors.textPrimary,
    letterSpacing: 0.1,
  );
  static const labelMedium = TextStyle(
    fontFamily: GFont.inter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: GColors.textSecondary,
    letterSpacing: 0.1,
  );
  static const labelSmall = TextStyle(
    fontFamily: GFont.inter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: GColors.textTertiary,
    letterSpacing: 0.5,
  );

  // Compteurs (Inter Tabular pour les chiffres fixes)
  static const counter = TextStyle(
    fontFamily: GFont.inter,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: GColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.0,
  );
  static const counterLarge = TextStyle(
    fontFamily: GFont.inter,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: GColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.5,
    height: 1.0,
  );

  // CTA / Boutons
  static const buttonPrimary = TextStyle(
    fontFamily: GFont.sora,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: GColors.textPrimary,
    letterSpacing: 0.2,
  );
}

abstract final class GDuration {
  static const Duration ultraFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  static const Duration splash = Duration(milliseconds: 1200);
}

abstract final class GBlur {
  static const double card = 12.0;
  static const double overlay = 20.0;
  static const double heavy = 40.0;
}

abstract final class GShadow {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> orangeGlow = [
    BoxShadow(
      color: GColors.orangeGlow,
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> redGlow = [
    BoxShadow(
      color: GColors.redGlow,
      blurRadius: 24,
      spreadRadius: 4,
    ),
  ];
}

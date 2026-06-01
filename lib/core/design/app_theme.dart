import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

abstract final class AppTheme {
  static ThemeData get darkTheme {
    // Google Fonts appliqué globalement — remplace les déclarations TTF locales
    final textThemeBase = GoogleFonts.soraTextTheme().copyWith(
      bodyLarge: GoogleFonts.inter(textStyle: GTextStyle.bodyLarge),
      bodyMedium: GoogleFonts.inter(textStyle: GTextStyle.bodyMedium),
      bodySmall: GoogleFonts.inter(textStyle: GTextStyle.bodySmall),
      labelLarge: GoogleFonts.inter(textStyle: GTextStyle.labelLarge),
      labelMedium: GoogleFonts.inter(textStyle: GTextStyle.labelMedium),
      labelSmall: GoogleFonts.inter(textStyle: GTextStyle.labelSmall),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GColors.black,
      colorScheme: const ColorScheme.dark(
        primary: GColors.orange,
        onPrimary: GColors.textPrimary,
        secondary: GColors.gold,
        onSecondary: GColors.textInverse,
        error: GColors.error,
        onError: GColors.textPrimary,
        surface: GColors.surface,
        onSurface: GColors.textPrimary,
      ),

      // ── AppBar ────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GTextStyle.headlineSmall,
        iconTheme: IconThemeData(color: GColors.textPrimary),
      ),

      // ── Text ─────────────────────────────────────────────────────
      textTheme: textThemeBase,

      // ── ElevatedButton ────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GColors.orange,
          foregroundColor: GColors.textPrimary,
          textStyle: GTextStyle.buttonPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.xl,
            vertical: GSpacing.md,
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GColors.orange,
          textStyle: GTextStyle.buttonPrimary,
          side: const BorderSide(color: GColors.orange, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.xl,
            vertical: GSpacing.md,
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      // ── TextButton ───────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GColors.orange,
          textStyle: GTextStyle.labelLarge,
        ),
      ),

      // ── InputDecoration ───────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GSpacing.md,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GRadius.md),
          borderSide: const BorderSide(color: GColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GRadius.md),
          borderSide: const BorderSide(color: GColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GRadius.md),
          borderSide: const BorderSide(color: GColors.orange, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GRadius.md),
          borderSide: const BorderSide(color: GColors.error, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GRadius.md),
          borderSide: const BorderSide(color: GColors.error, width: 1.0),
        ),
        hintStyle: GTextStyle.bodyLarge.copyWith(color: GColors.textTertiary),
        labelStyle: GTextStyle.bodySmall.copyWith(
          color: GColors.textTertiary,
          letterSpacing: 0.2,
        ),
        floatingLabelStyle: GTextStyle.bodySmall.copyWith(
          color: GColors.orange,
          fontSize: 12,
        ),
        errorStyle: GTextStyle.bodySmall.copyWith(color: GColors.error, fontSize: 11),
      ),

      // ── BottomNavigationBar ───────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: GColors.void_,
        selectedItemColor: GColors.orange,
        unselectedItemColor: GColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GTextStyle.labelSmall,
        unselectedLabelStyle: GTextStyle.labelSmall,
      ),

      // ── BottomSheet ───────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: GColors.surface,
        modalBackgroundColor: GColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(GRadius.xl),
          ),
        ),
        dragHandleColor: GColors.textTertiary,
        showDragHandle: true,
      ),

      // ── Dialog ────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: GColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GRadius.xl),
        ),
        titleTextStyle: GTextStyle.headlineMedium,
        contentTextStyle: GTextStyle.bodyMedium,
      ),

      // ── SnackBar ──────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GColors.elevated,
        contentTextStyle: GTextStyle.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ───────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: GColors.border,
        thickness: 0.5,
        space: 1,
      ),

      // ── IconButton ────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: GColors.textPrimary,
        ),
      ),

      // ── PageTransitions ───────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}

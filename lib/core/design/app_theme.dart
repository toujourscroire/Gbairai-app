import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';

abstract final class AppTheme {
  static ThemeData get darkTheme {
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
      textTheme: const TextTheme(
        displayLarge: GTextStyle.displayLarge,
        displayMedium: GTextStyle.displayMedium,
        displaySmall: GTextStyle.displaySmall,
        headlineLarge: GTextStyle.headlineLarge,
        headlineMedium: GTextStyle.headlineMedium,
        headlineSmall: GTextStyle.headlineSmall,
        bodyLarge: GTextStyle.bodyLarge,
        bodyMedium: GTextStyle.bodyMedium,
        bodySmall: GTextStyle.bodySmall,
        labelLarge: GTextStyle.labelLarge,
        labelMedium: GTextStyle.labelMedium,
        labelSmall: GTextStyle.labelSmall,
      ),

      // ── ElevatedButton ────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GColors.orange,
          foregroundColor: GColors.textPrimary,
          textStyle: GTextStyle.buttonPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.xl,
            vertical: GSpacing.md,
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GColors.orange,
          textStyle: GTextStyle.buttonPrimary,
          side: const BorderSide(color: GColors.orange, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.xl,
            vertical: GSpacing.md,
          ),
          minimumSize: const Size(double.infinity, 54),
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
          vertical: GSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GRadius.md),
          borderSide: const BorderSide(color: GColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GRadius.md),
          borderSide: const BorderSide(color: GColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GRadius.md),
          borderSide: const BorderSide(color: GColors.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GRadius.md),
          borderSide: const BorderSide(color: GColors.error),
        ),
        hintStyle: GTextStyle.bodyMedium.copyWith(color: GColors.textTertiary),
        labelStyle: GTextStyle.bodyMedium.copyWith(color: GColors.textSecondary),
        errorStyle: GTextStyle.bodySmall.copyWith(color: GColors.error),
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
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}

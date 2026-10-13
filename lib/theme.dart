import 'package:flutter/material.dart';

/// Identité de l'app : bleu nuit de la chouette, or de ses yeux.
class AppColors {
  static const navy = Color(0xFF22305A);
  static const navyDeep = Color(0xFF17213B);
  static const gold = Color(0xFFC99A3C);
  static const paper = Color(0xFFF3F1EC);
  static const bg = Color(0xFFEEF1F6);
  static const surface = Colors.white;
  static const ink = Color(0xFF17203A);
  static const muted = Color(0xFF5B6580);
  static const line = Color(0xFFD5DBE6);
  static const danger = Color(0xFFB3402F);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    primary: AppColors.navy,
    secondary: AppColors.gold,
    surface: AppColors.surface,
    error: AppColors.danger,
  );
  const display = 'Sora';
  const body = 'Figtree';
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: body);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: base.textTheme.copyWith(
      headlineSmall: const TextStyle(fontFamily: display, fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.ink, letterSpacing: -0.3),
      titleLarge: const TextStyle(fontFamily: display, fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.ink),
      titleMedium: const TextStyle(fontFamily: display, fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink),
      bodyMedium: const TextStyle(fontFamily: body, fontSize: 14, color: AppColors.ink, height: 1.4),
      bodySmall: const TextStyle(fontFamily: body, fontSize: 12.5, color: AppColors.muted, height: 1.35),
      labelLarge: const TextStyle(fontFamily: body, fontWeight: FontWeight.w600, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: display, fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.navy, width: 1.4)),
      labelStyle: const TextStyle(color: AppColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: body, fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size(0, 44),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

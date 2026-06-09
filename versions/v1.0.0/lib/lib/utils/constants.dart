import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFFDE6B5B);
  static const primaryLight = Color(0xFFFFE8E4);
  static const accent = Color(0xFF6B8E6B);
  static const warning = Color(0xFFE8A838);
  static const danger = Color(0xFFD35D47);
  static const info = Color(0xFF5B8FBF);
  static const bgPrimary = Color(0xFFFBF6F2);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF5EDE8);
  static const textPrimary = Color(0xFF2C2416);
  static const textSecondary = Color(0xFF8B8175);
  static const textHint = Color(0xFFC4BDB2);
  static const divider = Color(0xFFE8E3DA);
  static const border = Color(0xFFE0D8CF);

  static const List<int> tagColors = [
    0xFFDE6B5B, 0xFFE57373, 0xFFF06292, 0xFFBA68C8,
    0xFF9575CD, 0xFF7986CB, 0xFF64B5F6, 0xFF4FC3F7,
    0xFF4DD0E1, 0xFF4DB6AC, 0xFF81C784, 0xFFAED581,
    0xFFFFD54F, 0xFFFFB74D, 0xFFFF8A65, 0xFFA1887F,
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: Colors.white,
          error: AppColors.danger,
        ),
        scaffoldBackgroundColor: AppColors.bgPrimary,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgPrimary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 0.5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgSecondary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.primary : Colors.white),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.primary.withAlpha(60) : const Color(0xFFE0E0E0)),
        ),
      );
}

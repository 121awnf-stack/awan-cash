import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color sky = Color(0xFF0EA5E9);
  static const Color skyLight = Color(0xFF38BDF8);
  static const Color skyDeep = Color(0xFF0284C7);
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFF43F5E);
  static const Color transfer = Color(0xFF6366F1);
  static const Color warning = Color(0xFFF59E0B);
  static const Color neutral = Color(0xFF64748B);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF0F172A);

  static const LinearGradient cloudGradient = LinearGradient(
    colors: [skyLight, sky, skyDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.sky,
    brightness: brightness,
    primary: isDark ? AppColors.skyLight : AppColors.sky,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
  );
}

/// Warna latar kartu yang konsisten untuk mode terang/gelap.
Color cardColorOf(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? theme.colorScheme.surfaceContainerHigh
      : Colors.white;
}

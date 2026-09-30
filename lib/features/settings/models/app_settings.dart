import 'package:flutter/material.dart';

enum AppThemePalette {
  darkGreen,
  lightGreen,
  darkOrange,
  lightOrange,
}

class AppSettings {
  final AppThemePalette themePalette;
  final String language;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const AppSettings({
    this.themePalette = AppThemePalette.darkGreen,
    this.language = 'fa',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  AppSettings copyWith({
    AppThemePalette? themePalette,
    String? language,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return AppSettings(
      themePalette: themePalette ?? this.themePalette,
      language: language ?? this.language,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'themePalette': themePalette.name,
        'language': language,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    AppThemePalette palette = AppThemePalette.darkGreen;
    final paletteName = json['themePalette'] as String?;
    if (paletteName != null) {
      for (final p in AppThemePalette.values) {
        if (p.name == paletteName) {
          palette = p;
          break;
        }
      }
    }

    return AppSettings(
      themePalette: palette,
      language: (json['language'] as String?) ?? 'fa',
      soundEnabled: (json['soundEnabled'] as bool?) ?? true,
      vibrationEnabled: (json['vibrationEnabled'] as bool?) ?? true,
    );
  }

  ThemeData buildThemeData() {
    switch (themePalette) {
      case AppThemePalette.darkGreen:
        return _buildTheme(
          isDark: true,
          scaffoldBg: const Color(0xFF020617),
          surface: const Color(0xFF0F172A),
          surfaceElevated: const Color(0xFF1E293B),
          primary: const Color(0xFF10B981),
          secondary: const Color(0xFF06B6D4),
          border: const Color(0xFF334155),
          textPrimary: const Color(0xFFF8FAFC),
          textSecondary: const Color(0xFF94A3B8),
        );
      case AppThemePalette.lightGreen:
        return _buildTheme(
          isDark: false,
          scaffoldBg: const Color(0xFFF8FAFC),
          surface: const Color(0xFFFFFFFF),
          surfaceElevated: const Color(0xFFF1F5F9),
          primary: const Color(0xFF059669),
          secondary: const Color(0xFF0891B2),
          border: const Color(0xFFE2E8F0),
          textPrimary: const Color(0xFF0F172A),
          textSecondary: const Color(0xFF64748B),
        );
      case AppThemePalette.darkOrange:
        return _buildTheme(
          isDark: true,
          scaffoldBg: const Color(0xFF0C0A09),
          surface: const Color(0xFF1C1917),
          surfaceElevated: const Color(0xFF292524),
          primary: const Color(0xFFF97316),
          secondary: const Color(0xFFFBBF24),
          border: const Color(0xFF44403C),
          textPrimary: const Color(0xFFFAFAF9),
          textSecondary: const Color(0xFFA8A29E),
        );
      case AppThemePalette.lightOrange:
        return _buildTheme(
          isDark: false,
          scaffoldBg: const Color(0xFFFAFAF9),
          surface: const Color(0xFFFFFFFF),
          surfaceElevated: const Color(0xFFF5F5F4),
          primary: const Color(0xFFEA580C),
          secondary: const Color(0xFFD97706),
          border: const Color(0xFFE7E5E4),
          textPrimary: const Color(0xFF1C1917),
          textSecondary: const Color(0xFF78716C),
        );
    }
  }

  static ThemeData _buildTheme({
    required bool isDark,
    required Color scaffoldBg,
    required Color surface,
    required Color surfaceElevated,
    required Color primary,
    required Color secondary,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: surface,
      dividerColor: border,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: isDark ? const Color(0xFF020617) : Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceElevated,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: textSecondary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        labelStyle: TextStyle(color: textSecondary, fontSize: 12),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}

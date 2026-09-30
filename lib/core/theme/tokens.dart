import 'package:flutter/material.dart';

/// Central Design Tokens for BitcoinChecker.
/// Extends the dark green/cyan theme with strict semantic constraints.
/// All UI widgets must reference these tokens rather than hardcoded literals.
abstract class AppTokens {
  // --- Brand & Semantic Colors ---
  static const Color background = Color(0xFF020617); // Slate-950
  static const Color surface = Color(0xFF0F172A);    // Slate-900
  static const Color surfaceElevated = Color(0xFF1E293B); // Slate-800
  static const Color border = Color(0xFF334155);     // Slate-700
  static const Color borderSubtle = Color(0xFF1E293B);

  static const Color primary = Color(0xFF10B981);    // Emerald-500
  static const Color primarySubtle = Color(0x2610B981); // Emerald-500 @ 15%
  static const Color primaryHover = Color(0xFF34D399);

  static const Color secondary = Color(0xFF06B6D4);  // Cyan-500
  static const Color secondarySubtle = Color(0x2606B6D4);

  static const Color accent = Color(0xFF8B5CF6);     // Purple-500 (Composite rules)
  static const Color accentSubtle = Color(0x268B5CF6);

  static const Color positive = Color(0xFF10B981);  // Green up
  static const Color negative = Color(0xFFF43F5E);  // Rose down
  static const Color warning = Color(0xFFF59E0B);   // Amber (Cooldown)
  static const Color warningSubtle = Color(0x26F59E0B);

  static const Color textPrimary = Color(0xFFF8FAFC);   // Slate-50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate-400
  static const Color textMuted = Color(0xFF64748B);     // Slate-500

  // --- Spacing Scale ---
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // --- Border Radii ---
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge = 16.0;
  static const double radiusFull = 9999.0;

  static const BorderRadius borderSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderFull = BorderRadius.all(Radius.circular(radiusFull));

  // --- Typography Styles ---
  static const TextStyle displayTitle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );

  static const TextStyle monoNumbers = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle monoNumbersSmall = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

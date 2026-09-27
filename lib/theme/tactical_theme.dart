import 'package:flutter/material.dart';
import 'apple_theme.dart';

/// Legacy TacticalTheme interface proxied directly to Apple HIG Theme
class TacticalTheme {
  // Apple HIG Mappings
  static const Color bgPrimary = AppleTheme.systemBackground;
  static const Color bgSurface = AppleTheme.secondarySystemBackground;
  static const Color bgSurfaceElevated = AppleTheme.tertiarySystemBackground;
  static const Color bgSurfaceGlass = AppleTheme.glassSurface;

  // Apple Hairlines & Separators
  static const Color borderSubtle = AppleTheme.hairlineBorder;
  static const Color borderMedium = AppleTheme.separator;
  static const Color borderAccent = AppleTheme.systemBlue;

  // Apple Labels
  static const Color textPrimary = AppleTheme.label;
  static const Color textSecondary = AppleTheme.secondaryLabel;
  static const Color textMuted = AppleTheme.tertiaryLabel;
  static const Color textAccent = AppleTheme.systemBlue;

  // Apple System Accents
  static const Color accentBlue = AppleTheme.systemBlue;
  static const Color accentEmerald = AppleTheme.systemGreen;
  static const Color accentCyan = AppleTheme.systemTeal;
  static const Color accentAmber = AppleTheme.systemOrange;
  static const Color accentRose = AppleTheme.systemRed;
  static const Color accentPurple = AppleTheme.systemPurple;

  static ThemeData get themeData => AppleTheme.themeData;
}

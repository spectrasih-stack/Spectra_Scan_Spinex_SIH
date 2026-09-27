import 'package:flutter/material.dart';

/// Authentic Apple Human Interface Guidelines (HIG) Theme System
class AppleTheme {
  // Apple System Backgrounds (iOS Dark)
  static const Color systemBackground = Color(0xFF000000); // True OLED Black
  static const Color secondarySystemBackground = Color(0xFF1C1C1E); // Grouped Card Surface
  static const Color tertiarySystemBackground = Color(0xFF2C2C2E); // Elevated Surface
  static const Color systemGroupedBackground = Color(0xFF000000);
  static const Color secondarySystemGroupedBackground = Color(0xFF1C1C1E);

  // Translucent Materials & Frosted Glass
  static const Color glassSurface = Color(0xCC1C1C1E);
  static const Color glassSurfaceElevated = Color(0xD92C2C2E);
  static const Color glassNavBar = Color(0xB3121214);
  static const Color glassDock = Color(0xD91C1C1E);

  // Apple System Accents
  static const Color systemBlue = Color(0xFF0A84FF);
  static const Color systemGreen = Color(0xFF30D158);
  static const Color systemIndigo = Color(0xFF5E5CE6);
  static const Color systemOrange = Color(0xFFFF9F0A);
  static const Color systemPink = Color(0xFFFF375F);
  static const Color systemPurple = Color(0xFFBF5AF2);
  static const Color systemRed = Color(0xFFFF453A);
  static const Color systemTeal = Color(0xFF64D2FF);
  static const Color systemYellow = Color(0xFFFFD60A);
  static const Color systemMint = Color(0xFF63E6E2);
  static const Color systemCyan = Color(0xFF70D7FF);

  // Apple System Grays
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFF636366);
  static const Color systemGray3 = Color(0xFF48484A);
  static const Color systemGray4 = Color(0xFF3A3A3C);
  static const Color systemGray5 = Color(0xFF2C2C2E);
  static const Color systemGray6 = Color(0xFF1C1C1E);

  // Apple Text / Labels
  static const Color label = Color(0xFFFFFFFF);
  static const Color secondaryLabel = Color(0x99EBEBF5); // 60% opacity white
  static const Color tertiaryLabel = Color(0x4DEBEBF5); // 30% opacity white
  static const Color quaternaryLabel = Color(0x29EBEBF5); // 16% opacity white

  // Apple Separators & Hairlines
  static const Color separator = Color(0x33545458);
  static const Color opaqueSeparator = Color(0xFF38383A);
  static const Color hairlineBorder = Color(0x1FFFFFFF);

  // Squircle Radii
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
  static const double radiusCard = 22.0;
  static const double radiusPill = 32.0;

  // Spring & Slide Animation Durations
  static const Duration durationQuick = Duration(milliseconds: 200);
  static const Duration durationSpring = Duration(milliseconds: 380);
  static const Duration durationSmooth = Duration(milliseconds: 450);

  // Spring Physics Curves
  static const Curve curveSpring = Curves.easeOutCubic;
  static const Curve curveSlide = Curves.fastOutSlowIn;
  static const Curve curveBouncy = Curves.elasticOut;

  // Frosted Glass Box Decoration Helper
  static BoxDecoration frostedBox({
    Color color = glassSurface,
    BorderRadius? borderRadius,
    Color borderColor = hairlineBorder,
    double borderWidth = 0.5,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLarge),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: shadows ?? [
        BoxShadow(
          color: Colors.black.withAlpha(80),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Material 3 ThemeData with Apple HIG aesthetics
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: systemBackground,
      fontFamily: '.SF Pro Text',
      colorScheme: const ColorScheme.dark(
        primary: systemBlue,
        secondary: systemCyan,
        surface: secondarySystemBackground,
        error: systemRed,
        onPrimary: Colors.white,
        onSurface: label,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: label,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: systemBlue),
      ),
      cardTheme: CardThemeData(
        color: secondarySystemBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: hairlineBorder, width: 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tertiarySystemBackground,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: hairlineBorder, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: systemBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: label,
          side: const BorderSide(color: separator, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tertiarySystemBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: systemBlue, width: 1.5),
        ),
        labelStyle: const TextStyle(color: secondaryLabel, fontSize: 15),
        hintStyle: const TextStyle(color: tertiaryLabel, fontSize: 15),
      ),
      dividerTheme: const DividerThemeData(
        color: separator,
        thickness: 0.5,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Color tokens shared by the theme and by widgets that need raw values
/// (e.g. the syntax highlighter, which cannot rely on Theme.of(context)
/// inside a TextSpan builder that runs outside the widget tree).
class IdeColors {
  IdeColors._();

  // Dark palette — the app's primary identity.
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceAlt = Color(0xFF1C2128);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkTextPrimary = Color(0xFFE6EDF3);
  static const Color darkTextSecondary = Color(0xFF8B949E);

  static const Color accent = Color(0xFF4FC3F7);
  static const Color accentAlt = Color(0xFF7EE787);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFE3B341);
  static const Color success = Color(0xFF3FB950);

  // Syntax highlighting palette (dark).
  static const Color syntaxKeyword = Color(0xFFFF7B72);
  static const Color syntaxType = Color(0xFF79C0FF);
  static const Color syntaxFunction = Color(0xFFD2A8FF);
  static const Color syntaxString = Color(0xFFA5D6A7);
  static const Color syntaxNumber = Color(0xFFF2CC8F);
  static const Color syntaxComment = Color(0xFF6E7681);
  static const Color syntaxPreprocessor = Color(0xFFFFA657);
  static const Color syntaxOperator = Color(0xFFE6EDF3);
  static const Color syntaxClass = Color(0xFFFFA657);
  static const Color syntaxDefault = darkTextPrimary;

  // Light palette.
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF6F8FA);
  static const Color lightBorder = Color(0xFFD0D7DE);
  static const Color lightTextPrimary = Color(0xFF1F2328);
  static const Color lightTextSecondary = Color(0xFF57606A);
}

/// Consistent spacing/radius scale so padding and gaps stop being
/// scattered magic numbers across screens.
class IdeMetrics {
  IdeMetrics._();

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 10;
  static const double radiusLg = 12;

  static const double iconSm = 16;
  static const double iconMd = 18;
  static const double iconLg = 24;
}

class AppTheme {
  AppTheme._();

  static const String editorFontFamily = 'monospace';

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: IdeColors.accent,
        brightness: Brightness.dark,
        surface: IdeColors.darkSurface,
      ),
      scaffoldBackgroundColor: IdeColors.darkBackground,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: IdeColors.darkSurface,
        foregroundColor: IdeColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: IdeColors.darkSurfaceAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: IdeColors.darkBorder),
        ),
      ),
      dividerColor: IdeColors.darkBorder,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: IdeColors.darkSurface,
        selectedItemColor: IdeColors.accent,
        unselectedItemColor: IdeColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: IdeColors.accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: IdeColors.darkTextPrimary,
          side: const BorderSide(color: IdeColors.darkBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: IdeColors.darkSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: IdeColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: IdeColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: IdeColors.accent),
        ),
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: IdeColors.accent,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: IdeColors.lightBackground,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: IdeColors.lightSurface,
        foregroundColor: IdeColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: IdeColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: IdeColors.lightBorder),
        ),
      ),
      dividerColor: IdeColors.lightBorder,
    );
  }
}

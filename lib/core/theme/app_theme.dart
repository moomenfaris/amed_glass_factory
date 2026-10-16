import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette + Apple-style modern theme (clean, minimal, soft shadows).
class AppTheme {
  AppTheme._();

  static const Color appBarBlue = Color(0xFF0A192F);

  // ---- Brand colors ----
  static const Color brandDark = Color(0xFF30606C); // primary / deep teal
  static const Color brandMid = Color(0xFF7AA6B3); // secondary / soft teal
  static const Color brandLight = Color(
    0xFFF3F7FC,
  ); // background / app background

  // Aliases kept for callers that already use AppTheme.primary
  static const Color primary = brandDark;
  static const Color secondary = brandMid;

  // Functional colors
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color danger = Color(0xFFFF453A);

  static ThemeData light() {
    const surface = Colors.white;

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: brandLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandDark,
        brightness: Brightness.light,
        primary: brandDark,
        secondary: brandMid,
        surface: surface,
      ),
      textTheme: GoogleFonts.tajawalTextTheme(),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: _inputTheme(surface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandDark,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: GoogleFonts.tajawalTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFF1C1C1E),
        displayColor: const Color(0xFF1C1C1E),
      ),
    );
  }

  static ThemeData dark() {
    const bg = Color(0xFF0E1A1E);
    const surface = Color(0xFF1C2A2F);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandDark,
        brightness: Brightness.dark,
        primary: brandMid,
        secondary: brandLight,
        surface: surface,
      ),
      textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: _inputTheme(surface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandMid,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static InputDecorationTheme _inputTheme(Color fill) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: brandDark, width: 1.5),
      ),
    );
  }
}

const List<BoxShadow> kSoftShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 6)),
];

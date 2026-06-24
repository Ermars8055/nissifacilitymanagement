import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Warm Cream + Forest Green palette ────────────────────────────────────
  static const Color primary      = Color(0xFF1E3D2F); // Deep forest green
  static const Color primaryLight = Color(0xFFEBF2ED); // Light green tint
  static const Color cream        = Color(0xFFF7F3EC); // Warm ivory background
  static const Color creamDark    = Color(0xFFEEE8DF); // Slightly deeper cream
  static const Color surface      = Color(0xFFFFFFFF); // Pure white card

  static const Color textDark     = Color(0xFF1A1714); // Warm near-black
  static const Color textMedium   = Color(0xFF4A4540); // Warm dark gray
  static const Color textMuted    = Color(0xFF8C8278); // Warm muted

  static const Color success      = Color(0xFF2D6B4F); // Forest green
  static const Color warning      = Color(0xFFA05A10); // Warm amber
  static const Color error        = Color(0xFF9B2020); // Warm deep red
  static const Color info         = Color(0xFF1E5080); // Dark blue
  static const Color border       = Color(0xFFDDD5C8); // Warm light border

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: success,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: cream,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.w700, fontSize: 22),
        titleMedium: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge: GoogleFonts.inter(color: textDark, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: textMedium, fontSize: 15),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.only(bottom: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: creamDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: const TextStyle(color: Color(0xFFBBB3A8), fontSize: 15),
        labelStyle: const TextStyle(color: textMedium, fontSize: 15),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEDE7DD), thickness: 1),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : Colors.transparent),
        side: const BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}

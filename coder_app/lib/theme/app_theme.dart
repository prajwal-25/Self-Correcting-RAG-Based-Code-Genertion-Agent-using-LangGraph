import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF8B5CF6); // violet
  static const Color secondary = Color(0xFF06B6D4); // cyan
  static const Color surface = Color(0xFF1E1E2E);
  static const Color surfaceVariant = Color(0xFF2A2A3E);
  static const Color background = Color(0xFF13131F);
  static const Color onBackground = Color(0xFFE2E8F0);
  static const Color onSurface = Color(0xFFCDD6F4);
  static const Color subtle = Color(0xFF6C7086);
  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFF38BA8);
  static const Color codeBackground = Color(0xFF11111B);

  // Gradient used in the hero header
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
      bodyMedium: GoogleFonts.inter(color: onSurface, fontSize: 14),
      bodySmall: GoogleFonts.inter(color: subtle, fontSize: 12),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: onSurface,
        error: error,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFF2A2A3E), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: subtle, fontSize: 14),
        suffixIconColor: subtle,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: subtle,
        indicatorColor: primary,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
        dividerColor: surfaceVariant,
        overlayColor: WidgetStateProperty.all(primary.withValues(alpha: 0.08)),
      ),
      dividerColor: surfaceVariant,
      iconTheme: const IconThemeData(color: subtle),
    );
  }
}

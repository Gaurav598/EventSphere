import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6C63FF); // Modern Indigo
  static const Color secondaryColor = Color(0xFF03DAC6); // Teal accent
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color errorColor = Color(0xFFCF6679);

  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      brightness: brightness,
      background: isDark ? backgroundDark : const Color(0xFFF8F9FA),
      surface: isDark ? surfaceDark : Colors.white,
      error: errorColor,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.background,
      
      // Premium Typography
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: colorScheme.onBackground),
        displayMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: colorScheme.onBackground),
        displaySmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: colorScheme.onBackground),
        headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: colorScheme.onBackground),
        headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: colorScheme.onBackground),
        titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: colorScheme.onBackground),
        titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: colorScheme.onBackground),
        bodyLarge: GoogleFonts.plusJakartaSans(color: colorScheme.onBackground.withOpacity(0.87)),
        bodyMedium: GoogleFonts.plusJakartaSans(color: colorScheme.onBackground.withOpacity(0.87)),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onBackground,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryColor, width: 2),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: colorScheme.onSurface.withOpacity(0.7)),
        hintStyle: GoogleFonts.plusJakartaSans(color: colorScheme.onSurface.withOpacity(0.4)),
      ),

      cardTheme: CardThemeData(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: isDark ? 0 : 4,
        shadowColor: Colors.black.withOpacity(0.05),
        color: colorScheme.surface,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 24,
        backgroundColor: colorScheme.surface,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: colorScheme.onSurface.withOpacity(0.8),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface.withOpacity(0.1),
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 8,
        backgroundColor: colorScheme.surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.5),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppTheme {
  // Option B: Coastal Twilight Teal & Golden Sunset Theme
  static const Color midnightTeal = Color(0xFF0C1B24);      // Deep oceanic midnight base
  static const Color surfaceTeal = Color(0xFF132836);       // Twilight card background
  static const Color surfaceElevated = Color(0xFF1B3547);   // Highlighted / hover card background
  static const Color borderTeal = Color(0xFF26475C);        // Subdued border
  static const Color borderGlow = Color(0xFF14B8A6);        // Vibrant cyan/teal border glow

  static const Color oceanTeal = Color(0xFF14B8A6);         // Primary seafoam turquoise
  static const Color oceanTealDark = Color(0xFF0D9488);     // Deeper teal
  static const Color sunsetGold = Color(0xFFF59E0B);        // Radiant sunset amber/gold
  static const Color sunsetCoral = Color(0xFFF97316);       // Warm sunset coral accent
  static const Color textCream = Color(0xFFF8FAFC);         // Crisp cream/white typography
  static const Color textMuted = Color(0xFF94A3B8);         // Slate gray secondary typography
  static const Color textSubtle = Color(0xFF64748B);        // Subtle tertiary text
  static const Color emergencyRed = Color(0xFFEF4444);      // Emergency SOS badge

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: oceanTeal,
      scaffoldBackgroundColor: midnightTeal,
      colorScheme: const ColorScheme.dark(
        primary: oceanTeal,
        secondary: sunsetGold,
        surface: surfaceTeal,
        onSurface: textCream,
        error: emergencyRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: midnightTeal,
        elevation: 0,
        iconTheme: IconThemeData(color: textCream),
        titleTextStyle: TextStyle(
          color: textCream,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceTeal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderTeal),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceTeal,
        indicatorColor: oceanTeal.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: sunsetGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            );
          }
          return const TextStyle(color: textMuted, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: sunsetGold, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),
      ),
      useMaterial3: true,
    );
  }
}

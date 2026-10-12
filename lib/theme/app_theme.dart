import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App color tokens and kid-friendly premium design theme
class AppColors {
  // Required palette colors
  static const Color coralPink = Color(0xFFFF5B67);
  static const Color sunshineYellow = Color(0xFFFFD447);
  static const Color mintGreen = Color(0xFF64DDA0);
  static const Color skyBlue = Color(0xFF58C7FA);
  static const Color grapePurple = Color(0xFF9875FF);
  static const Color tangerine = Color(0xFFFF9638);
  static const Color hotPink = Color(0xFFFF79B0);
  static const Color deepNavy = Color(0xFF25264A);
  static const Color softCream = Color(0xFFFFF9F0);

  // Additional support shades
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color canvasPaper = Color(0xFFFDFAF5);
  static const Color cardShadow = Color(0x1A25264A);
  static const Color outlineDark = Color(0xFF1E1F3B);
  static const Color lightGray = Color(0xFFEDE8E3);
  static const Color textSecondary = Color(0xFF6B6C8C);
  static const Color successGreen = Color(0xFF38D39F);

  // Playful gradients
  static const LinearGradient rainbowGradient = LinearGradient(
    colors: [
      coralPink,
      tangerine,
      sunshineYellow,
      mintGreen,
      skyBlue,
      grapePurple,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coralSunset = LinearGradient(
    colors: [coralPink, tangerine],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunshineMint = LinearGradient(
    colors: [sunshineYellow, mintGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient berryBlast = LinearGradient(
    colors: [hotPink, grapePurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient oceanBreeze = LinearGradient(
    colors: [skyBlue, mintGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.softCream,
      primaryColor: AppColors.coralPink,
      fontFamily: GoogleFonts.fredoka().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.coralPink,
        primary: AppColors.coralPink,
        secondary: AppColors.sunshineYellow,
        tertiary: AppColors.mintGreen,
        surface: AppColors.softCream,
        onSurface: AppColors.deepNavy,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.deepNavy, size: 26),
        titleTextStyle: GoogleFonts.fredoka(
          color: AppColors.deepNavy,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x1225264A), width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: AppColors.cardShadow,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

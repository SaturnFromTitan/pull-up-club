import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class AppTypography {
  AppTypography._();

  // Playful app title style
  static final TextStyle displayAppTitle = GoogleFonts.poppins(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 1.2,
  );

  // Regular display styles
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 35,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.3,
  );

  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
  );

  static TextStyle displaySmall = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // Headline styles
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.56,
    letterSpacing: -0.43,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: -0.44,
  );

  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: -0.29,
  );

  // Body styles
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );
}

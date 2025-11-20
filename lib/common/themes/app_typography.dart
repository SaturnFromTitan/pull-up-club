import "package:flutter/material.dart";

class AppTypography {
  AppTypography._();

  // Playful app title style
  static const TextStyle displayAppTitle = TextStyle(
    fontFamily: "Poppins",
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 1.5,
  );

  // Regular display styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: "Inter",
    fontSize: 35,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: "Inter",
    fontSize: 30,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: "Inter",
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1,
  );

  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: "Inter",
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.56,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: "Inter",
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: "Inter",
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: "Inter",
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: "Inter",
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: "Inter",
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );
}

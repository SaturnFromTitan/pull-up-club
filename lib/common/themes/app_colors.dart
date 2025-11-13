import "package:flutter/material.dart";

class AppColors {
  // surface colors
  static const Color surfaceLight = Color(0xF0FFFFFF); //94% opacity
  // we're using gradients instead of primary and secondary colors

  // Text colors
  static const Color onColor = Colors.white;
  static const Color onColorSecondary = Color(0xCCFFFFFF);
  static const Color onLight = Color(0xFF2D3748);
  static const Color onLightSecondary = Color(0xFF4A5565);

  // Shadow colors
  static const Color shadow = Color(0x1A000000); // 10% black opacity

  // Glassmorphism colors - White overlays for dark background
  static const Color glassBackground = Color(0x1AFFFFFF); // 10% white opacity
  static const Color glassBorderActive = Color(0xB3FFFFFF); // 70% white opacity
  static const Color glassBorderInactive = Color(0x33FFFFFF); // 20% white opacity}

  // accents, icons, etc.
  static const Color yellow = Color(0xFFFDC700);
  static const Color gold = Color(0xFFFFE680);

  // Skip Rest button colors
  static const Color skipRestBorder = Color(0x80FF8904);
  static const Color skipRestText = Color(0xFFFFD6A7);

  // Gradient color lists
  static const List<Color> gradientPrimary = [Color(0xFFF6339A), Color(0xFFFF6900)];
  static const List<Color> gradientSecondary = [Color(0xFF00C950), Color(0xFF2B7FFF)];
  static const List<Color> gradientSurface = [
    Color(0xFF9810FA),
    Color(0xFF155DFC),
    Color(0xFF372AAC),
  ];
  static const List<Color> gradientSurfaceOnLight = [
    Color(0xFFDBEAFE),
    Color(0xFFBEDBFF),
  ];
  static const List<Color> gradientAccentPurple = [
    Color(0xFF8B5CF6),
    Color(0xFF6D28D9),
  ];
  static const List<Color> gradientAccentGreen = [Color(0xFF22C55E), Color(0xFF16A34A)];
  static const List<Color> gradientRepCount = [Color(0xFF155DFC), Color(0xFF0092B8)];
  static const List<Color> gradientLightOpaque = [Color(0x1AFFFFFF), Color(0x12FFFFFF)];
  static const List<Color> gradientSkipRest = [Color(0x33FF6900), Color(0x33FF8904)];
}

class AppGradients {
  static const LinearGradient surface = LinearGradient(
    colors: AppColors.gradientSurface,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient surfaceOnLight = LinearGradient(
    colors: AppColors.gradientSurfaceOnLight,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient primary = LinearGradient(
    colors: AppColors.gradientPrimary,
  );
  static const LinearGradient secondary = LinearGradient(
    colors: AppColors.gradientSecondary,
  );
  static const LinearGradient accentPurple = LinearGradient(
    colors: AppColors.gradientAccentPurple,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGreen = LinearGradient(
    colors: AppColors.gradientAccentGreen,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient repCount = LinearGradient(
    colors: AppColors.gradientRepCount,
  );
  static const LinearGradient light = LinearGradient(
    colors: [AppColors.surfaceLight, AppColors.glassBorderActive],
  );
  static const LinearGradient lightOpaque = LinearGradient(
    colors: AppColors.gradientLightOpaque,
  );
  static const LinearGradient skipRest = LinearGradient(
    colors: AppColors.gradientSkipRest,
  );
}

Color getTextColorOnGradient(
  final LinearGradient gradient,
  final BuildContext context,
) {
  final scheme = Theme.of(context).colorScheme;
  final onLight = scheme.onSurface; // for light/white surfaces
  final onColor = scheme.onPrimary; // for colored surfaces

  final c0 = gradient.colors.first;
  final c1 = gradient.colors.last;
  final mid = Color.lerp(c0, c1, 0.5)!;

  final brightness = ThemeData.estimateBrightnessForColor(mid);
  return brightness == Brightness.dark ? onColor : onLight;
}

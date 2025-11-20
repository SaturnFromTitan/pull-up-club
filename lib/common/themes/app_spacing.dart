import "package:flutter/material.dart";

class AppSpacing {
  // Base spacing unit (4px)
  static const double base = 4;

  // Spacing scale
  static const double xs = base; // 4px
  static const double sm = base * 2; // 8px
  static const double md = base * 4; // 16px
  static const double lg = base * 6; // 24px
  static const double xl = base * 8; // 32px
  static const double xxl = base * 10; // 40px
  static const double xxxl = base * 16; // 64px

  // Border radius
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusFull = 999;

  // Padding
  static const double paddingSm = 20;
  static const double paddingMd = 30;
  static const double paddingLg = 40;

  // Specific spacing values from design
  static const double buttonHeight = 60;
  static const double buttonDistance = sm;
}

class Screen {
  Screen._();

  static double height(final BuildContext c) => MediaQuery.of(c).size.height;
  static double width(final BuildContext c) => MediaQuery.of(c).size.width;

  static const double _tinyThreshold = 700;
  static const double _smallThreshold = 840;
  static bool isTiny(final BuildContext c) => height(c) < _tinyThreshold;
  static bool isSmall(final BuildContext c) => height(c) < _smallThreshold;
}

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_colors.dart";

/// Drop-in wrapper for your colorful cards/headers
class GradientSurface extends StatelessWidget {
  const GradientSurface({
    required this.gradient,
    super.key,
    this.child,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.height,
    this.width,
    this.textColor,
  });
  final LinearGradient gradient;
  final Widget? child;
  final Border? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? height;
  final double? width;
  final Color? textColor;

  @override
  Widget build(final BuildContext context) {
    final actualTextColor = textColor ?? getTextColorOnGradient(gradient, context);

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: child != null
          ? DefaultTextStyle.merge(
              style: TextStyle(color: actualTextColor),
              child: IconTheme.merge(
                data: IconThemeData(color: actualTextColor),
                child: child!,
              ),
            )
          : null,
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<LinearGradient>("gradient", gradient))
      ..add(DiagnosticsProperty<Border?>("border", border))
      ..add(DiagnosticsProperty<BorderRadius?>("borderRadius", borderRadius))
      ..add(IterableProperty<BoxShadow>("boxShadow", boxShadow))
      ..add(DoubleProperty("height", height))
      ..add(DoubleProperty("width", width))
      ..add(DiagnosticsProperty<Color?>("textColor", textColor));
  }
}

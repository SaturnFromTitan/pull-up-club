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
  });
  final LinearGradient gradient;
  final Widget? child;
  final Border? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? height;
  final double? width;

  @override
  Widget build(final BuildContext context) {
    final textColor = getTextColorOnGradient(gradient, context);

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
              style: TextStyle(color: textColor),
              child: IconTheme.merge(
                data: IconThemeData(color: textColor),
                child: child!,
              ),
            )
          : null,
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LinearGradient>("gradient", gradient));
    properties.add(DiagnosticsProperty<Border?>("border", border));
    properties.add(
      DiagnosticsProperty<BorderRadius?>("borderRadius", borderRadius),
    );
    properties.add(IterableProperty<BoxShadow>("boxShadow", boxShadow));
    properties.add(DoubleProperty("height", height));
    properties.add(DoubleProperty("width", width));
  }
}

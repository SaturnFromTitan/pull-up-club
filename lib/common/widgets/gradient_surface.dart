import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_colors.dart";

/// Drop-in wrapper for your colorful cards/headers
class GradientSurface extends StatelessWidget {
  final LinearGradient gradient;
  final Widget? child;
  final Border? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? height;
  final double? width;

  const GradientSurface({
    super.key,
    required this.gradient,
    this.child,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
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
}

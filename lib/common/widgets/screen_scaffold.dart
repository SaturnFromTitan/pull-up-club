import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_colors.dart";

class ScreenScaffold extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;

  const ScreenScaffold({
    super.key,
    required this.child,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    const gradient = AppGradients.surface;

    // not using GradientSurface as the DefaultTextStyle would be overridden
    // by Scaffolds text styles
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final textColor = getTextColorOnGradient(gradient, context);

              return Padding(
                padding: EdgeInsets.only(
                  top: AppSpacing.lg,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: bottomNavigationBar == null ? AppSpacing.lg : 0,
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: textColor),
                  child: IconTheme.merge(
                    data: IconThemeData(color: textColor),
                    child: child,
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

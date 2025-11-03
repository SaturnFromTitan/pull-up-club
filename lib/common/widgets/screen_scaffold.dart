import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";

class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({required this.child, super.key, this.bottomNavigationBar});
  final Widget child;
  final Widget? bottomNavigationBar;

  @override
  Widget build(final BuildContext context) {
    const gradient = AppGradients.surface;

    // not using GradientSurface as the DefaultTextStyle would be overridden
    // by Scaffolds text styles
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: gradient),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Builder(
            builder: (final context) {
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

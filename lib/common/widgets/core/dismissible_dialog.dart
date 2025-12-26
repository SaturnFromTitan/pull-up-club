import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";

class DismissibleDialog extends StatelessWidget {
  const DismissibleDialog({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(final BuildContext context) {
    return Dialog(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.paddingLg),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: IconButton(
              icon: const Icon(
                LucideIcons.x,
                size: 30,
                color: AppColors.onLightSecondary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Widget>("children", children));
  }
}

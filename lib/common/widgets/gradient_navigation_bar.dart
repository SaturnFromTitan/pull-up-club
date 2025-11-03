import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_typography.dart";

class GradientNavigationBar extends StatelessWidget {
  const GradientNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    super.key,
  });
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  static const double _iconSize = 25;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: AppGradients.light),
    child: SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(destinations.length, (final index) {
            final destination = destinations[index];
            final isSelected = index == selectedIndex;
            final iconWidget = (isSelected && destination.selectedIcon != null)
                ? destination.selectedIcon!
                : destination.icon;
            return _NavItem(
              isSelected: isSelected,
              icon: iconWidget,
              label: destination.label,
              onTap: () => onDestinationSelected(index),
            );
          }),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty("selectedIndex", selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          "onDestinationSelected",
          onDestinationSelected,
        ),
      );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final bool isSelected;
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  static const Color _inactiveColor = AppColors.onLightSecondary;

  @override
  Widget build(final BuildContext context) {
    final labelStyle = AppTypography.bodyMedium.copyWith(
      color: isSelected ? Colors.white : _inactiveColor,
    );

    final Widget coloredIcon = IconTheme(
      data: IconThemeData(
        size: GradientNavigationBar._iconSize,
        color: isSelected ? Colors.white : _inactiveColor,
      ),
      child: icon,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primary : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            coloredIcon,
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: labelStyle),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>("isSelected", isSelected))
      ..add(StringProperty("label", label))
      ..add(ObjectFlagProperty<VoidCallback>.has("onTap", onTap));
  }
}

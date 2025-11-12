import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/common/shell_screen.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/widgets/gradient_button.dart";

class HomeButton extends StatelessWidget {
  const HomeButton({
    required this.text,
    super.key,
    this.icon = Icons.home,
    this.gradient = AppGradients.light,
  });
  final String text;
  final IconData icon;
  final LinearGradient gradient;

  @override
  Widget build(final BuildContext context) {
    return GradientButton(
      onPressed: () async {
        context.read<NavigationProvider>().resetTab();

        await Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(Shell.route, (final route) => false);
      },
      text: text,
      icon: icon,
      gradient: gradient,
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty("text", text))
      ..add(DiagnosticsProperty<IconData>("icon", icon))
      ..add(DiagnosticsProperty<LinearGradient>("gradient", gradient));
  }
}

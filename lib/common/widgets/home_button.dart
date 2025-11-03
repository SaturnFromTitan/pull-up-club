import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/providers/app_provider.dart";
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
  Widget build(final BuildContext context) => GradientButton(
    onPressed: () {
      context.read<AppProvider>().resetTab();

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(Shell.route, (final route) => false);
    },
    text: text,
    icon: icon,
    gradient: gradient,
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty("text", text));
    properties.add(DiagnosticsProperty<IconData>("icon", icon));
    properties.add(DiagnosticsProperty<LinearGradient>("gradient", gradient));
  }
}

import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_colors.dart";

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.onColor),
      ),
    );
  }
}

import "package:flutter/material.dart";

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(final BuildContext context) => const Center(
    child: Image(image: AssetImage("assets/images/app-icon-transparent.png")),
  );
}

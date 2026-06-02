import 'package:flutter/material.dart';

import '../core/animations/animation_type.dart';
import '../core/animations/universal_animation_screen.dart';
import '../core/theme/app_assets.dart';
import 'login_demo_page.dart';

class AppIntroScreen extends StatelessWidget {
  const AppIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UniversalAnimationScreen(
      animationPath: 'assets/animations/app_intro.mp4',
      animationType: AnimationType.video,
      backgroundColor: const Color(0xFF5B5F82),
      allowSkip: false,
      enableVibration: false,
      enableFinalFlash: false,
      fallbackWidget: const _IntroFallback(),
      onFinished: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginDemoPage()),
      ),
    );
  }
}

class _IntroFallback extends StatelessWidget {
  const _IntroFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        AppAssets.logoHorizontal,
        width: 300,
        fit: BoxFit.contain,
      ),
    );
  }
}

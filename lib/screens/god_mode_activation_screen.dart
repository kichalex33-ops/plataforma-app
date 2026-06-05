import 'package:flutter/material.dart';

import '../core/animations/animation_type.dart';
import '../core/animations/universal_animation_screen.dart';
import '../core/session/app_access_mode.dart';
import 'god_mode_dashboard.dart';

class GodModeActivationScreen extends StatelessWidget {
  const GodModeActivationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UniversalAnimationScreen(
      animationPath: 'assets/animations/god_mode_activation.mp4',
      animationType: AnimationType.video,
      backgroundColor: Colors.black,
      allowSkip: false,
      enableVibration: true,
      enableFinalFlash: true,
      fallbackWidget: const _GodModeFallback(),
      onFinished: () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const GodModeDashboard(accessMode: AppAccessMode.godMode),
        ),
        (_) => false,
      ),
    );
  }
}

class _GodModeFallback extends StatelessWidget {
  const _GodModeFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_shipping, color: Colors.white, size: 86),
          const SizedBox(height: 24),
          const Text(
            'GOD MODE',
            style: TextStyle(
              color: Color(0xFFFF0000),
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

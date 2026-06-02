import 'dart:async';

import 'package:flutter/material.dart';

import '../core/session/app_access_mode.dart';
import '../core/theme/app_assets.dart';
import '../core/theme/app_colors.dart';
import 'module_selector_page.dart';

class GodModeIntroPage extends StatefulWidget {
  const GodModeIntroPage({super.key});

  @override
  State<GodModeIntroPage> createState() => _GodModeIntroPageState();
}

class _GodModeIntroPageState extends State<GodModeIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    Timer(const Duration(milliseconds: 4600), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ModuleSelectorPage(accessMode: AppAccessMode.godMode),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final lineProgress = (_controller.value * 1.4).clamp(0.0, 1.0);
          final pulse = 0.55 + (_controller.value * 0.45);
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GodModeLinesPainter(progress: lineProgress),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _scale.value,
                        child: Opacity(
                          opacity: _fade.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: pulse),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.28),
                                  blurRadius: 42 * pulse,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              AppAssets.logo,
                              width: 190,
                              height: 190,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      Opacity(
                        opacity: _controller.value > 0.45 ? _fade.value : 0,
                        child: const Text(
                          'GOD MODE ATIVADO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: _controller.value > 0.62 ? _fade.value : 0,
                        child: const Text(
                          'Acesso total liberado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GodModeLinesPainter extends CustomPainter {
  final double progress;

  const _GodModeLinesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.34;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -1.35, 4.8 * progress, false, paint);

    final linePaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.34)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final endX = size.width * progress;
    canvas.drawLine(
      Offset(0, size.height * 0.22),
      Offset(endX, size.height * 0.18),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height * 0.78),
      Offset(size.width - endX, size.height * 0.82),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GodModeLinesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

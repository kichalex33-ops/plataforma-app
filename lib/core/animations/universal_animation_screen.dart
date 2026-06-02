import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart';
import 'package:video_player/video_player.dart';
import 'package:vibration/vibration.dart';

import 'animation_type.dart';

class UniversalAnimationScreen extends StatefulWidget {
  final String animationPath;
  final AnimationType animationType;
  final Color backgroundColor;
  final VoidCallback onFinished;
  final bool allowSkip;
  final bool enableVibration;
  final bool enableFinalFlash;
  final Widget fallbackWidget;

  const UniversalAnimationScreen({
    super.key,
    required this.animationPath,
    required this.animationType,
    required this.backgroundColor,
    required this.onFinished,
    required this.allowSkip,
    required this.enableVibration,
    required this.enableFinalFlash,
    required this.fallbackWidget,
  });

  @override
  State<UniversalAnimationScreen> createState() =>
      _UniversalAnimationScreenState();
}

class _UniversalAnimationScreenState extends State<UniversalAnimationScreen> {
  VideoPlayerController? _videoController;
  bool _failed = false;
  bool _finished = false;
  bool _flash = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (widget.animationType == AnimationType.video) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(widget.animationPath);
    _videoController = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      controller
        ..setLooping(false)
        ..addListener(_videoListener)
        ..play();
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
      Timer(const Duration(milliseconds: 1400), _finish);
    }
  }

  void _videoListener() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    final position = controller.value.position;
    final duration = controller.value.duration;
    if (duration != Duration.zero && position >= duration) {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    final hasVibrator = await Vibration.hasVibrator();
    if (widget.enableVibration && hasVibrator) {
      await Vibration.vibrate(duration: 300);
    }
    if (widget.enableFinalFlash && mounted) {
      setState(() => _flash = true);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.allowSkip,
      child: Scaffold(
        backgroundColor: widget.backgroundColor,
        body: GestureDetector(
          onTap: widget.allowSkip ? _finish : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: widget.backgroundColor,
                child: _failed ? widget.fallbackWidget : _buildAnimation(),
              ),
              if (_flash)
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _flash ? 0.42 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const ColoredBox(color: Color(0xFFFF0000)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimation() {
    return switch (widget.animationType) {
      AnimationType.video => _buildVideo(),
      AnimationType.lottie => Lottie.asset(
          widget.animationPath,
          fit: BoxFit.cover,
          repeat: false,
          onLoaded: (composition) {
            Timer(composition.duration, _finish);
          },
        ),
      AnimationType.rive => RiveAnimation.asset(
          widget.animationPath,
          fit: BoxFit.cover,
          onInit: (_) {
            Timer(const Duration(seconds: 4), _finish);
          },
        ),
    };
  }

  Widget _buildVideo() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/auth/driver_pairing_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';

class QrPairingScreen extends StatefulWidget {
  final DriverPairingService? pairingService;

  const QrPairingScreen({super.key, this.pairingService});

  @override
  State<QrPairingScreen> createState() => _QrPairingScreenState();
}

class _QrPairingScreenState extends State<QrPairingScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (raw == null || raw.trim().isEmpty) return;

    setState(() {
      _processing = true;
      _error = null;
    });
    await _controller.stop();

    try {
      final result = await (widget.pairingService ?? DriverPairingService())
          .pairFromRawQr(raw);
      if (!mounted) return;
      Navigator.pop(context, result);
    } on DriverPairingException catch (error) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = error.message;
      });
      await _controller.start();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = 'Nao foi possivel validar o QR Code no painel.';
      });
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        title: const Text('Parear com QR Code'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.gold, width: 3),
                    ),
                  ),
                ),
                if (_processing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: AppColors.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Aponte a camera para o QR Code gerado no painel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Depois do pareamento, use o login e a senha inicial gerados pelo painel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

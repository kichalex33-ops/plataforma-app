import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../rastreamento/models/rastreamento_ponto_model.dart';
import '../../transportes/models/viagem_model.dart';
import 'tracking_legend.dart';

class TrackingMapPanel extends StatelessWidget {
  final List<RastreamentoPontoModel> pontos;
  final List<ViagemModel> viagens;
  final VoidCallback onRefresh;

  const TrackingMapPanel({
    super.key,
    required this.pontos,
    required this.viagens,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final viagem = viagens.isNotEmpty ? viagens.first : null;
    return Container(
      height: 430,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0EA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4ECE7)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TrackingPainter(pontos: pontos),
              child: const SizedBox.expand(),
            ),
          ),
          const Positioned(
            top: 18,
            left: 18,
            child: Text(
              'Rastreamento em Tempo Real',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Positioned(
            top: 58,
            left: 16,
            child: Column(
              children: [
                const _MapButton(icon: Icons.add),
                const SizedBox(height: 7),
                const _MapButton(icon: Icons.remove),
                const SizedBox(height: 18),
                const _MapButton(icon: Icons.my_location),
                const SizedBox(height: 18),
                const _MapButton(icon: Icons.layers_rounded),
                const SizedBox(height: 18),
                _MapButton(icon: Icons.refresh, onTap: onRefresh),
              ],
            ),
          ),
          Positioned(
            left: 86,
            bottom: 54,
            child: _RouteSummary(
              viagem: viagem,
              ponto: pontos.isNotEmpty ? pontos.first : null,
            ),
          ),
          const Positioned(right: 20, bottom: 24, child: TrackingLegend()),
          if (pontos.isEmpty)
            const Positioned.fill(child: Center(child: _MapPlaceholderNote())),
        ],
      ),
    );
  }
}

class _TrackingPainter extends CustomPainter {
  final List<RastreamentoPontoModel> pontos;

  const _TrackingPainter({required this.pontos});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFEAF1EC);
    canvas.drawRect(Offset.zero & size, bg);

    final minorRoad = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = 2;
    final majorRoad = Paint()
      ..color = const Color(0xFFE9C56B)
      ..strokeWidth = 3;
    for (var i = 0; i < 9; i++) {
      final y = size.height * (.12 + i * .09);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + math.sin(i * 1.4) * 28),
        i.isEven ? majorRoad : minorRoad,
      );
      final x = size.width * (.08 + i * .11);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + math.cos(i) * 34, size.height),
        minorRoad,
      );
    }

    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final route = Path()
      ..moveTo(size.width * .20, size.height * .30)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .42,
        size.width * .50,
        size.height * .22,
      )
      ..quadraticBezierTo(
        size.width * .64,
        size.height * .58,
        size.width * .80,
        size.height * .18,
      );
    canvas.drawPath(route, routePaint);

    final sample = [
      (
        Offset(size.width * .22, size.height * .30),
        const Color(0xFF168039),
        Icons.directions_bus,
      ),
      (
        Offset(size.width * .50, size.height * .42),
        const Color(0xFF168039),
        Icons.directions_bus,
      ),
      (
        Offset(size.width * .63, size.height * .58),
        const Color(0xFFE53935),
        Icons.directions_car,
      ),
      (
        Offset(size.width * .78, size.height * .18),
        const Color(0xFFFB8C00),
        Icons.local_taxi,
      ),
      (
        Offset(size.width * .70, size.height * .78),
        const Color(0xFF9AA3AA),
        Icons.directions_car,
      ),
    ];

    for (var i = 0; i < sample.length; i++) {
      final marker = sample[i];
      final position = pontos.isNotEmpty && i == 0
          ? Offset(size.width * .50, size.height * .42)
          : marker.$1;
      canvas.drawCircle(position, 13, Paint()..color = Colors.white);
      canvas.drawCircle(position, 10, Paint()..color = marker.$2);
      final icon = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(marker.$3.codePoint),
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: marker.$3.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      icon.paint(canvas, position - Offset(icon.width / 2, icon.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TrackingPainter oldDelegate) {
    return oldDelegate.pontos.length != pontos.length;
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MapButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 19, color: AppColors.textStrong),
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  final ViagemModel? viagem;
  final RastreamentoPontoModel? ponto;

  const _RouteSummary({required this.viagem, required this.ponto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4ECE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Viagem selecionada',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  viagem?.status ?? 'sem rota',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoLine('Origem', viagem?.origem ?? '-'),
          _InfoLine('Destino', viagem?.destino ?? '-'),
          _InfoLine('Último ponto', ponto?.timestamp ?? 'sem localização'),
          TextButton(
            onPressed: viagem == null ? null : () {},
            child: const Text('Ver detalhes'),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholderNote extends StatelessWidget {
  const _MapPlaceholderNote();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(999),
        ),
        // TODO: substituir pelo componente real de mapa/rastreamento quando
        // endpoint cartográfico estiver disponível no servidor.
        child: const Text(
          'Mapa institucional: aguardando pontos reais de rastreamento',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

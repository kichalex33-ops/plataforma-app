import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../database/database_helper.dart';
import '../../models/lira_lia_visita_model.dart';
import '../../models/rg_quarteirao_model.dart';

class MapaDemoPage extends StatefulWidget {
  const MapaDemoPage({super.key});

  @override
  State<MapaDemoPage> createState() => _MapaDemoPageState();
}

class _MapaDemoPageState extends State<MapaDemoPage> {
  List<RGQuarteiraoModel> quarteiroes = [];
  List<LiraLiaVisitaModel> liraLia = [];

  @override
  void initState() {
    super.initState();
    carregarCamadas();
  }

  Future<void> carregarCamadas() async {
    final rg = await DatabaseHelper.instance.listarRGQuarteiroes();
    final registros = await DatabaseHelper.instance.listarLiraLiaVisitas();

    if (!mounted) return;

    setState(() {
      quarteiroes = rg;
      liraLia = registros;
    });
  }

  List<Widget> construirPinsRG(Size size) {
    if (quarteiroes.isEmpty) return [];

    final latitudes = quarteiroes.map((item) => item.latitude).toList();
    final longitudes = quarteiroes.map((item) => item.longitude).toList();
    final minLat = latitudes.reduce((a, b) => a < b ? a : b);
    final maxLat = latitudes.reduce((a, b) => a > b ? a : b);
    final minLng = longitudes.reduce((a, b) => a < b ? a : b);
    final maxLng = longitudes.reduce((a, b) => a > b ? a : b);
    final positivos = liraLia
        .where((item) => item.focosPositivos > 0)
        .map((item) => item.rgQuarteiraoCodigo)
        .toSet();

    return quarteiroes.map((item) {
      final x = ((item.longitude - minLng) / (maxLng - minLng)) * size.width;
      final y = ((maxLat - item.latitude) / (maxLat - minLat)) * size.height;
      final cor = positivos.contains(item.codigo)
          ? AppColors.atrasado
          : AppColors.primary;

      return Positioned(
        left: x.clamp(18, size.width - 34).toDouble(),
        top: y.clamp(112, size.height - 130).toDouble(),
        child: _RGPin(codigo: item.codigo, color: cor),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa Territorial')),
      body: RefreshIndicator(
        onRefresh: carregarCamadas,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _SaoJoseMapPainter()),
                    ),
                    ...construirPinsRG(size),
                    const Positioned(
                      top: 24,
                      left: 20,
                      right: 20,
                      child: _MapaHeader(),
                    ),
                    const Positioned(
                      top: 132,
                      left: 58,
                      child: _MapaPin.emDia(),
                    ),
                    const Positioned(
                      top: 188,
                      left: 142,
                      child: _MapaPin.vencendo(),
                    ),
                    const Positioned(
                      top: 250,
                      left: 88,
                      child: _MapaPin.atrasado(),
                    ),
                    const Positioned(
                      top: 156,
                      right: 72,
                      child: _MapaPin.ovitrampa(),
                    ),
                    const Positioned(
                      top: 306,
                      right: 116,
                      child: _MapaPin.bti(),
                    ),
                    Positioned(
                      right: 16,
                      top: 132,
                      child: Column(
                        children: const [
                          _MapControl(icon: Icons.add),
                          SizedBox(height: 8),
                          _MapControl(icon: Icons.remove),
                          SizedBox(height: 8),
                          _MapControl(icon: Icons.my_location),
                          SizedBox(height: 8),
                          _MapControl(icon: Icons.layers),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 22,
                      child: _LayerPanel(
                        quarteiroes: quarteiroes.length,
                        positivos: liraLia
                            .where((item) => item.focosPositivos > 0)
                            .length,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MapaHeader extends StatelessWidget {
  const _MapaHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.map, color: AppColors.primary),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sao Jose do Sul',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Mapa demo offline - RG, PEs e camadas epidemiologicas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RGPin extends StatelessWidget {
  final String codigo;
  final Color color;

  const _RGPin({required this.codigo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Quarteirao RG $codigo',
      child: Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          codigo.length > 2 ? codigo.substring(0, 2) : codigo,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 7,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LayerPanel extends StatelessWidget {
  final int quarteiroes;
  final int positivos;

  const _LayerPanel({required this.quarteiroes, required this.positivos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Camadas visiveis',
            style: TextStyle(
              color: AppColors.textStrong,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              const _LayerChip(color: AppColors.emDia, label: 'PE em dia'),
              const _LayerChip(color: AppColors.vencendo, label: 'Vencendo'),
              const _LayerChip(color: AppColors.atrasado, label: 'Atrasado'),
              const _LayerChip(
                color: AppColors.ovitrampas,
                label: 'Ovitrampas',
              ),
              const _LayerChip(color: AppColors.bti, label: 'BTI'),
              _LayerChip(color: AppColors.primary, label: 'RG: $quarteiroes'),
              if (positivos > 0)
                _LayerChip(
                  color: AppColors.atrasado,
                  label: 'Focos: $positivos',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LayerChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControl extends StatelessWidget {
  final IconData icon;

  const _MapControl({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

class _MapaPin extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _MapaPin({required this.color, required this.icon});

  const _MapaPin.emDia()
    : this(color: AppColors.emDia, icon: Icons.location_on);
  const _MapaPin.vencendo()
    : this(color: AppColors.vencendo, icon: Icons.location_on);
  const _MapaPin.atrasado()
    : this(color: AppColors.atrasado, icon: Icons.location_on);
  const _MapaPin.ovitrampa()
    : this(color: AppColors.ovitrampas, icon: Icons.bug_report);
  const _MapaPin.bti() : this(color: AppColors.bti, icon: Icons.water_drop);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _SaoJoseMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFD8EAF0),
    );

    final areaPaint = Paint()
      ..color = const Color(0xFFCFE6C7)
      ..style = PaintingStyle.fill;
    final areaBorder = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.32)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final municipio = Path()
      ..moveTo(size.width * 0.18, size.height * 0.20)
      ..lineTo(size.width * 0.42, size.height * 0.12)
      ..lineTo(size.width * 0.72, size.height * 0.22)
      ..lineTo(size.width * 0.86, size.height * 0.46)
      ..lineTo(size.width * 0.68, size.height * 0.72)
      ..lineTo(size.width * 0.34, size.height * 0.78)
      ..lineTo(size.width * 0.13, size.height * 0.58)
      ..close();

    canvas.drawPath(municipio, areaPaint);
    canvas.drawPath(municipio, areaBorder);

    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.86)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final roadLine = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.16)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roads = [
      Path()
        ..moveTo(-20, size.height * 0.38)
        ..quadraticBezierTo(
          size.width * 0.42,
          size.height * 0.30,
          size.width + 24,
          size.height * 0.44,
        ),
      Path()
        ..moveTo(size.width * 0.25, -20)
        ..quadraticBezierTo(
          size.width * 0.42,
          size.height * 0.46,
          size.width * 0.30,
          size.height + 20,
        ),
      Path()
        ..moveTo(size.width * 0.04, size.height * 0.72)
        ..quadraticBezierTo(
          size.width * 0.46,
          size.height * 0.52,
          size.width * 0.92,
          size.height * 0.66,
        ),
    ];

    for (final road in roads) {
      canvas.drawPath(road, roadPaint);
      canvas.drawPath(road, roadLine);
    }

    final heatPaint = Paint()
      ..color = AppColors.atrasado.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 0.40),
      52,
      heatPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class TerritorialMapPreview extends StatelessWidget {
  final VoidCallback onAbrirMapa;
  final String municipio;

  const TerritorialMapPreview({
    super.key,
    required this.onAbrirMapa,
    this.municipio = 'Sao Jose do Sul',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 224,
      decoration: BoxDecoration(
        color: const Color(0xFFDDECD8),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: _OsmPreviewTiles()),
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            child: _MapBadge(
              icon: Icons.layers,
              text: municipio,
              color: AppColors.primary,
            ),
          ),
          const Positioned(
            top: 70,
            left: 54,
            child: _MapPin(label: 'PE', color: AppColors.emDia),
          ),
          const Positioned(
            top: 112,
            left: 112,
            child: _MapPin(label: 'RG', color: AppColors.vencendo),
          ),
          const Positioned(
            top: 80,
            right: 70,
            child: _MapPin(label: 'FOCO', color: AppColors.atrasado),
          ),
          const Positioned(
            bottom: 56,
            right: 112,
            child: _MapPin(label: 'BTI', color: AppColors.bti),
          ),
          Positioned(
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: Column(
              children: [
                _SquareMapButton(icon: Icons.add, onPressed: onAbrirMapa),
                const SizedBox(height: 6),
                _SquareMapButton(icon: Icons.remove, onPressed: onAbrirMapa),
                const SizedBox(height: 6),
                _SquareMapButton(
                  icon: Icons.my_location,
                  onPressed: onAbrirMapa,
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Material(
              color: Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: InkWell(
                onTap: onAbrirMapa,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.public, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mapa territorial operacional',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textStrong,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'OpenStreetMap, PE, RG, BTI, ovitrampas e focos',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF445766),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: onAbrirMapa,
                        child: const Text('Abrir'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OsmPreviewTiles extends StatelessWidget {
  static const _tileSize = 256.0;
  static const _zoom = 14;
  static const _centroLat = -29.5406;
  static const _centroLng = -51.4848;

  const _OsmPreviewTiles();

  double _longitudeParaTileX(double longitude) {
    final n = math.pow(2.0, _zoom).toDouble();
    return (longitude + 180.0) / 360.0 * n;
  }

  double _latitudeParaTileY(double latitude) {
    final latRad = latitude * math.pi / 180.0;
    final n = math.pow(2.0, _zoom).toDouble();
    return (1.0 -
            math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) / math.pi) /
        2.0 *
        n;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final centroX = _longitudeParaTileX(_centroLng);
        final centroY = _latitudeParaTileY(_centroLat);
        final baseX = centroX.floor();
        final baseY = centroY.floor();
        final tilesHorizontais = (size.width / _tileSize).ceil() + 2;
        final tilesVerticais = (size.height / _tileSize).ceil() + 2;
        final inicioX = baseX - tilesHorizontais ~/ 2;
        final inicioY = baseY - tilesVerticais ~/ 2;
        final maxTile = math.pow(2, _zoom).toInt();

        return Stack(
          children: [
            for (var dx = 0; dx <= tilesHorizontais; dx++)
              for (var dy = 0; dy <= tilesVerticais; dy++)
                if (inicioY + dy >= 0 && inicioY + dy < maxTile)
                  Positioned(
                    left: (inicioX + dx - centroX) * _tileSize +
                        size.width / 2,
                    top: (inicioY + dy - centroY) * _tileSize +
                        size.height / 2,
                    width: _tileSize,
                    height: _tileSize,
                    child: Image.network(
                      'https://tile.openstreetmap.org/$_zoom/${((inicioX + dx) % maxTile + maxTile) % maxTile}/${inicioY + dy}.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(
                          color: Color(0xFFDDECD8),
                          child: Center(
                            child: Icon(
                              Icons.map_outlined,
                              color: Colors.black38,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MapBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SquareMapButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Material(
        color: Colors.white.withValues(alpha: 0.98),
        elevation: 2,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final String label;
  final Color color;

  const _MapPin({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: color, size: 22),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

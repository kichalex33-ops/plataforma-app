import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class RouteSummaryPanel extends StatelessWidget {
  final String origem;
  final String destino;
  final String horario;
  final String? finalidade;

  const RouteSummaryPanel({
    super.key,
    required this.origem,
    required this.destino,
    required this.horario,
    this.finalidade,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rota da viagem',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _RoutePoint(
              icon: Icons.trip_origin,
              label: 'Origem',
              value: origem,
            ),
            Container(
              margin: const EdgeInsets.only(left: 11),
              height: 24,
              width: 2,
              color: AppColors.primaryLight,
            ),
            _RoutePoint(icon: Icons.flag, label: 'Destino', value: destino),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Chip(label: Text(horario)),
                if (finalidade?.isNotEmpty == true)
                  Chip(label: Text(finalidade!)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RoutePoint({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

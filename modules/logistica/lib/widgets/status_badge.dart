import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final String? status;

  const StatusBadge({super.key, required this.label, this.status});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status ?? label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _colorFor(String value) {
    final normalizado = value.toLowerCase();
    if (normalizado.contains('andamento') ||
        normalizado.contains('online') ||
        normalizado.contains('iniciada')) {
      return AppColors.informativo;
    }
    if (normalizado.contains('conclu') ||
        normalizado.contains('synced') ||
        normalizado.contains('confirm')) {
      return AppColors.emDia;
    }
    if (normalizado.contains('cancel') ||
        normalizado.contains('failed') ||
        normalizado.contains('ausente') ||
        normalizado.contains('offline')) {
      return AppColors.atrasado;
    }
    return AppColors.primary;
  }
}

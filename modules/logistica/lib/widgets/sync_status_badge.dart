import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SyncStatusBadge extends StatelessWidget {
  final String status;

  const SyncStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final data = _statusData(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: data.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 14, color: data.color),
          const SizedBox(width: 6),
          Text(
            data.label,
            style: TextStyle(
              color: data.color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  _SyncStatusData _statusData(String value) {
    switch (value) {
      case 'synced':
        return const _SyncStatusData(
          'sincronizado',
          AppColors.emDia,
          Icons.cloud_done,
        );
      case 'failed':
        return const _SyncStatusData(
          'falhou',
          AppColors.atrasado,
          Icons.cloud_off,
        );
      case 'conflict':
        return const _SyncStatusData(
          'conflito',
          Color(0xFF7E57C2),
          Icons.compare_arrows,
        );
      case 'processing':
        return const _SyncStatusData(
          'enviando',
          AppColors.informativo,
          Icons.sync,
        );
      default:
        return const _SyncStatusData(
          'pendente',
          AppColors.vencendo,
          Icons.cloud_upload,
        );
    }
  }
}

class _SyncStatusData {
  final String label;
  final Color color;
  final IconData icon;

  const _SyncStatusData(this.label, this.color, this.icon);
}

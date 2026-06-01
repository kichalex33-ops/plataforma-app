import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/sync_queue_item_model.dart';
import '../../../widgets/status_badge.dart';
import 'dashboard_section_card.dart';

class SyncStatusPanel extends StatelessWidget {
  final Map<String, int> porStatus;
  final List<SyncQueueItemModel> recentes;

  const SyncStatusPanel({
    super.key,
    required this.porStatus,
    required this.recentes,
  });

  @override
  Widget build(BuildContext context) {
    final pendentes = porStatus['pending'] ?? 0;
    final falhas = porStatus['failed'] ?? 0;
    return DashboardSectionCard(
      title: 'Pendências de Sincronização',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Counter(
                label: 'Pendentes',
                value: '$pendentes',
                color: const Color(0xFFFB8C00),
              ),
              const SizedBox(width: 10),
              _Counter(
                label: 'Falhas',
                value: '$falhas',
                color: const Color(0xFFE53935),
              ),
              const SizedBox(width: 10),
              _Counter(
                label: 'Sincronizados',
                value: '${porStatus['synced'] ?? 0}',
                color: const Color(0xFF168039),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (recentes.isEmpty)
            const Text(
              'Fila de sincronização sem registros recentes.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...recentes
                .take(4)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.entityType} / ${item.operation}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        StatusBadge(label: item.status),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Counter({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 21,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

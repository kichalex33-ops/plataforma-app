import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'status_badge.dart';

class SyncStatusCard extends StatelessWidget {
  final bool online;
  final String title;
  final String description;
  final String? lastSync;
  final int? pending;
  final Widget? child;

  const SyncStatusCard({
    super.key,
    required this.online,
    required this.title,
    required this.description,
    this.lastSync,
    this.pending,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (online ? AppColors.emDia : AppColors.atrasado)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Icon(
                    online ? Icons.cloud_done : Icons.cloud_off,
                    color: online ? AppColors.emDia : AppColors.atrasado,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textStrong,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: online ? 'Online' : 'Offline'),
              ],
            ),
            if (lastSync?.isNotEmpty == true || pending != null) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (lastSync?.isNotEmpty == true)
                    Chip(label: Text('Ultimo sync: $lastSync')),
                  if (pending != null)
                    Chip(label: Text('Pendencias: $pending')),
                ],
              ),
            ],
            if (child != null) ...[
              const SizedBox(height: AppSpacing.md),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

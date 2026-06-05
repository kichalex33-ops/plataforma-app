import 'package:flutter/material.dart';

import '../../core/connectivity/models/connectivity_status.dart';
import '../../core/sync/models/sync_status.dart';

class SyncStatusCard extends StatelessWidget {
  final ConnectivityStatus connectivityStatus;
  final SyncStatus syncStatus;
  final int pendingItems;
  final DateTime? lastSuccessfulSync;
  final String? errorMessage;
  final VoidCallback? onSyncTap;

  const SyncStatusCard({
    super.key,
    required this.connectivityStatus,
    required this.syncStatus,
    required this.pendingItems,
    this.lastSuccessfulSync,
    this.errorMessage,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context);
    final icon = _iconFor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_subtitle, style: Theme.of(context).textTheme.bodySmall),
                  if (errorMessage?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onSyncTap != null)
              IconButton(
                tooltip: 'Sincronizar agora',
                onPressed: onSyncTap,
                icon: const Icon(Icons.sync),
              ),
          ],
        ),
      ),
    );
  }

  String get _title {
    if (syncStatus == SyncStatus.syncing) return 'Sincronizando';
    if (syncStatus == SyncStatus.failed) return 'Erro de sincronizacao';
    if (pendingItems > 0) return '$pendingItems pendente(s)';
    if (connectivityStatus == ConnectivityStatus.offline) return 'Offline';
    return 'Tudo sincronizado';
  }

  String get _subtitle {
    final connection = connectivityStatus.label;
    final lastSync = lastSuccessfulSync == null
        ? 'sem envio concluido'
        : 'ultimo envio ${_format(lastSuccessfulSync!)}';

    return '$connection | $lastSync';
  }

  IconData _iconFor() {
    if (syncStatus == SyncStatus.failed) return Icons.error_outline;
    if (syncStatus == SyncStatus.syncing) return Icons.sync;
    if (pendingItems > 0) return Icons.cloud_upload_outlined;
    if (connectivityStatus == ConnectivityStatus.offline) {
      return Icons.cloud_off_outlined;
    }
    return Icons.cloud_done_outlined;
  }

  Color _colorFor(BuildContext context) {
    if (syncStatus == SyncStatus.failed) return Colors.red.shade700;
    if (syncStatus == SyncStatus.syncing) return Colors.blue.shade700;
    if (pendingItems > 0) return Colors.orange.shade800;
    if (connectivityStatus == ConnectivityStatus.offline) {
      return Colors.grey.shade700;
    }
    return Colors.green.shade700;
  }

  String _format(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

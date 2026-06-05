import '../connectivity/models/connectivity_status.dart';
import '../sync/models/sync_status.dart';
import '../sync/repositories/sync_queue_repository.dart';
import 'audit_agent.dart';
import 'connectivity_agent.dart';

class AppHealthSnapshot {
  final int pendingItems;
  final DateTime? lastSuccessfulSync;
  final List<String> recentErrors;
  final SyncStatus status;
  final ConnectivityStatus connectivityStatus;
  final int auditEvents;

  const AppHealthSnapshot({
    required this.pendingItems,
    required this.lastSuccessfulSync,
    required this.recentErrors,
    required this.status,
    required this.connectivityStatus,
    required this.auditEvents,
  });
}

class AppHealthAgent {
  final SyncQueueRepository repository;
  final AuditAgent auditAgent;
  final ConnectivityAgent connectivityAgent;

  AppHealthAgent({
    required this.repository,
    required this.auditAgent,
    required this.connectivityAgent,
  });

  Future<AppHealthSnapshot> snapshot() async {
    final pending = await repository.unsyncedCount();
    final lastSync = await repository.lastSuccessfulSync();
    final errors = await repository.recentErrors();

    return AppHealthSnapshot(
      pendingItems: pending,
      lastSuccessfulSync: lastSync,
      recentErrors: errors,
      status: _resolveStatus(
        pendingItems: pending,
        lastSuccessfulSync: lastSync,
        recentErrors: errors,
      ),
      connectivityStatus: connectivityAgent.status,
      auditEvents: auditAgent.events.length,
    );
  }

  SyncStatus _resolveStatus({
    required int pendingItems,
    required DateTime? lastSuccessfulSync,
    required List<String> recentErrors,
  }) {
    if (recentErrors.isNotEmpty) return SyncStatus.failed;
    if (pendingItems > 0) return SyncStatus.pending;
    if (lastSuccessfulSync != null) return SyncStatus.synced;
    return SyncStatus.pending;
  }
}

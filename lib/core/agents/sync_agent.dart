import '../connectivity/models/connectivity_status.dart';
import '../sync/models/sync_operation_type.dart';
import '../sync/models/sync_queue_item.dart';
import '../sync/services/sync_queue_service.dart';
import 'audit_agent.dart';
import 'connectivity_agent.dart';

class SyncAgent {
  final SyncQueueService queueService;
  final ConnectivityAgent connectivityAgent;
  final AuditAgent auditAgent;

  SyncAgent({
    required this.queueService,
    required this.connectivityAgent,
    required this.auditAgent,
  }) {
    connectivityAgent.addListener(_handleConnectivityChange);
  }

  Future<DateTime?> get lastSuccessfulSync => queueService.lastSuccessfulSync();

  Future<SyncQueueItem> registerEvent({
    required SyncOperationType operationType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) {
    return queueService.enqueue(
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
    );
  }

  Future<SyncRunResult> syncNow() async {
    if (!connectivityAgent.canSync) {
      auditAgent.registerSkipped(
        message:
            'Conexao ${connectivityAgent.status.value}; itens locais preservados.',
      );
      return SyncRunResult.skipped();
    }

    auditAgent.registerAttempt();
    final result = await queueService.syncPending(canSync: true);

    if (result.failed > 0) {
      auditAgent.registerFailure(error: result.error ?? 'Erro desconhecido.');
    } else {
      auditAgent.registerCompleted(
        message: 'Sincronizacao concluida com ${result.sent} item(ns).',
      );
    }

    return result;
  }

  Future<void> _handleConnectivityChange(ConnectivityStatus status) async {
    if (status.canSync) {
      await syncNow();
    }
  }
}

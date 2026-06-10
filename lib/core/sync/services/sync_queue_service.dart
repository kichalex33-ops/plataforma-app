import '../models/sync_operation_type.dart';
import '../models/sync_queue_item.dart';
import '../models/sync_status.dart';
import '../repositories/sync_queue_repository.dart';
import 'api_sync_dispatcher.dart';

typedef SyncDispatcher = Future<void> Function(SyncQueueItem item);

class SyncRunResult {
  final int attempted;
  final int sent;
  final int failed;
  final bool skipped;
  final String? error;
  final DateTime? completedAt;

  const SyncRunResult({
    required this.attempted,
    required this.sent,
    required this.failed,
    this.skipped = false,
    this.error,
    this.completedAt,
  });

  factory SyncRunResult.skipped() {
    return const SyncRunResult(attempted: 0, sent: 0, failed: 0, skipped: true);
  }
}

class SyncQueueService {
  final SyncQueueRepository repository;
  final SyncDispatcher dispatcher;
  final int maxAttempts;

  SyncQueueService({
    required this.repository,
    required this.dispatcher,
    this.maxAttempts = 5,
  });

  Future<SyncQueueItem> enqueue({
    required SyncOperationType operationType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final item = SyncQueueItem.pending(
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
    );
    await repository.save(item);
    return item;
  }

  Future<SyncRunResult> syncPending({required bool canSync}) async {
    if (!canSync) {
      return SyncRunResult.skipped();
    }

    final pending = (await repository.listPending())
        .where((item) => item.attempts < maxAttempts)
        .toList(growable: false);
    var sent = 0;
    var failed = 0;
    String? lastError;

    for (final item in pending) {
      final attemptAt = DateTime.now();
      final processing = item.copyWith(
        status: SyncStatus.syncing,
        attempts: item.attempts + 1,
        lastAttemptAt: attemptAt,
        clearError: true,
      );
      await repository.update(processing);

      try {
        await dispatcher(processing);
        await repository.update(
          processing.copyWith(
            status: SyncStatus.synced,
            syncedAt: DateTime.now(),
            clearError: true,
          ),
        );
        sent++;
      } on SyncConflictException catch (error) {
        lastError = 'CONFLITO: ${error.message}';
        await repository.update(
          processing.copyWith(
            status: SyncStatus.failed,
            attempts: maxAttempts,
            error: lastError,
          ),
        );
        failed++;
      } catch (error) {
        final exhausted = processing.attempts >= maxAttempts;
        lastError = exhausted ? 'MAX_TENTATIVAS: $error' : error.toString();
        await repository.update(
          processing.copyWith(status: SyncStatus.failed, error: lastError),
        );
        failed++;
      }
    }

    return SyncRunResult(
      attempted: pending.length,
      sent: sent,
      failed: failed,
      error: lastError,
      completedAt: DateTime.now(),
    );
  }

  Future<int> unsyncedCount() => repository.unsyncedCount();

  Future<DateTime?> lastSuccessfulSync() => repository.lastSuccessfulSync();
}

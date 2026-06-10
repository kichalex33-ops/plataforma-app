import '../models/sync_queue_item.dart';
import '../models/sync_status.dart';

abstract class SyncQueueRepository {
  Future<void> save(SyncQueueItem item);

  Future<void> update(SyncQueueItem item);

  Future<List<SyncQueueItem>> listAll();

  Future<List<SyncQueueItem>> listPending({int limit = 50});

  Future<int> unsyncedCount();

  Future<DateTime?> lastSuccessfulSync();

  Future<List<String>> recentErrors({int limit = 5});
}

class InMemorySyncQueueRepository implements SyncQueueRepository {
  final List<SyncQueueItem> _items = <SyncQueueItem>[];

  @override
  Future<void> save(SyncQueueItem item) async {
    final index = _items.indexWhere((current) => current.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
  }

  @override
  Future<void> update(SyncQueueItem item) => save(item);

  @override
  Future<List<SyncQueueItem>> listAll() async {
    return List<SyncQueueItem>.unmodifiable(_items);
  }

  @override
  Future<List<SyncQueueItem>> listPending({int limit = 50}) async {
    final pending = _items
        .where((item) => item.status != SyncStatus.synced)
        .take(limit)
        .toList(growable: false);
    return pending;
  }

  @override
  Future<int> unsyncedCount() async {
    return _items.where((item) => item.status != SyncStatus.synced).length;
  }

  @override
  Future<DateTime?> lastSuccessfulSync() async {
    final synced =
        _items
            .where((item) => item.syncedAt != null)
            .map((item) => item.syncedAt!)
            .toList(growable: false)
          ..sort((a, b) => b.compareTo(a));
    return synced.isEmpty ? null : synced.first;
  }

  @override
  Future<List<String>> recentErrors({int limit = 5}) async {
    return _items
        .where((item) => item.error != null && item.error!.trim().isNotEmpty)
        .toList(growable: false)
        .reversed
        .take(limit)
        .map((item) => item.error!)
        .toList(growable: false);
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

class SharedPreferencesSyncQueueRepository implements SyncQueueRepository {
  final String storageKey;

  const SharedPreferencesSyncQueueRepository({
    this.storageKey = 'core_sync_queue_items',
  });

  @override
  Future<void> save(SyncQueueItem item) async {
    final items = await _load();
    final index = items.indexWhere((current) => current.id == item.id);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await _persist(items);
  }

  @override
  Future<void> update(SyncQueueItem item) => save(item);

  @override
  Future<List<SyncQueueItem>> listAll() async {
    return List<SyncQueueItem>.unmodifiable(await _load());
  }

  @override
  Future<List<SyncQueueItem>> listPending({int limit = 50}) async {
    return (await _load())
        .where((item) => item.status != SyncStatus.synced)
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<int> unsyncedCount() async {
    return (await _load())
        .where((item) => item.status != SyncStatus.synced)
        .length;
  }

  @override
  Future<DateTime?> lastSuccessfulSync() async {
    final synced =
        (await _load())
            .where((item) => item.syncedAt != null)
            .map((item) => item.syncedAt!)
            .toList(growable: false)
          ..sort((a, b) => b.compareTo(a));
    return synced.isEmpty ? null : synced.first;
  }

  @override
  Future<List<String>> recentErrors({int limit = 5}) async {
    return (await _load())
        .where((item) => item.error != null && item.error!.trim().isNotEmpty)
        .toList(growable: false)
        .reversed
        .take(limit)
        .map((item) => item.error!)
        .toList(growable: false);
  }

  Future<List<SyncQueueItem>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <SyncQueueItem>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <SyncQueueItem>[];
    }

    return decoded
        .whereType<Map>()
        .map((item) => SyncQueueItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: true);
  }

  Future<void> _persist(List<SyncQueueItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(storageKey, raw);
  }
}

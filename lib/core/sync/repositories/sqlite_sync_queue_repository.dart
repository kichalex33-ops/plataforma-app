import 'dart:convert';

import 'package:plataforma_logistica_driver/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

import '../models/sync_operation_type.dart';
import '../models/sync_queue_item.dart';
import '../models/sync_status.dart';
import 'sync_queue_repository.dart';

class SQLiteSyncQueueRepository implements SyncQueueRepository {
  static const table = 'core_sync_queue_items';

  final DatabaseHelper databaseHelper;

  SQLiteSyncQueueRepository({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<Database> get _db async {
    final db = await databaseHelper.database;
    await _ensureSchema(db);
    return db;
  }

  @override
  Future<void> save(SyncQueueItem item) async {
    final db = await _db;
    await db.insert(
      table,
      _toRow(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(SyncQueueItem item) => save(item);

  @override
  Future<List<SyncQueueItem>> listAll() async {
    final db = await _db;
    final rows = await db.query(table, orderBy: 'created_at ASC');
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<SyncQueueItem>> listPending({int limit = 50}) async {
    final db = await _db;
    final rows = await db.query(
      table,
      where: 'status != ?',
      whereArgs: [SyncStatus.synced.value],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<int> unsyncedCount() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $table WHERE status != ?',
      [SyncStatus.synced.value],
    );
    return int.tryParse(rows.first['total'].toString()) ?? 0;
  }

  @override
  Future<DateTime?> lastSuccessfulSync() async {
    final db = await _db;
    final rows = await db.query(
      table,
      columns: const ['synced_at'],
      where: 'synced_at IS NOT NULL',
      orderBy: 'synced_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['synced_at'].toString());
  }

  @override
  Future<List<String>> recentErrors({int limit = 5}) async {
    final db = await _db;
    final rows = await db.query(
      table,
      columns: const ['error'],
      where: 'error IS NOT NULL AND error != ""',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map((row) => row['error'].toString()).toList(growable: false);
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $table (
        id TEXT PRIMARY KEY,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_attempt_at TEXT,
        synced_at TEXT,
        error TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_core_sync_status ON $table(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_core_sync_created ON $table(created_at)',
    );
  }

  Map<String, Object?> _toRow(SyncQueueItem item) {
    return {
      'id': item.id,
      'operation_type': item.operationType.value,
      'entity_type': item.entityType,
      'entity_id': item.entityId,
      'payload_json': jsonEncode(item.payload),
      'status': item.status.value,
      'attempts': item.attempts,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
      'last_attempt_at': item.lastAttemptAt?.toIso8601String(),
      'synced_at': item.syncedAt?.toIso8601String(),
      'error': item.error,
    };
  }

  SyncQueueItem _fromRow(Map<String, Object?> row) {
    return SyncQueueItem.fromJson({
      'id': row['id'],
      'operation_type': row['operation_type'],
      'entity_type': row['entity_type'],
      'entity_id': row['entity_id'],
      'payload': jsonDecode(row['payload_json']?.toString() ?? '{}'),
      'status': row['status'],
      'attempts': row['attempts'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
      'last_attempt_at': row['last_attempt_at'],
      'synced_at': row['synced_at'],
      'error': row['error'],
    });
  }
}

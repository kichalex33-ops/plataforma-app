import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/sync_queue_item_model.dart';
import '../services/device_id_service.dart';

class SyncQueueRepository {
  final DatabaseHelper databaseHelper;
  final DeviceIdService deviceIdService;

  SyncQueueRepository({
    DatabaseHelper? databaseHelper,
    DeviceIdService? deviceIdService,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       deviceIdService = deviceIdService ?? const DeviceIdService();

  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final deviceId = await deviceIdService.getDeviceId();
    final normalizedPayload = jsonEncode(payload);
    final checksum = sha256.convert(utf8.encode(normalizedPayload)).toString();

    await db.insert(
      'sync_queue',
      SyncQueueItemModel(
        id: const Uuid().v4(),
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: normalizedPayload,
        checksum: checksum,
        status: 'pending',
        retryCount: 0,
        deviceId: deviceId,
        version: 1,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncQueueItemModel>> listarPendentes({int limit = 50}) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'sync_queue',
      where: 'status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return result.map(SyncQueueItemModel.fromMap).toList();
  }

  Future<List<SyncQueueItemModel>> listarRecentes({int limit = 20}) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'sync_queue',
      orderBy: 'updated_at DESC, created_at DESC',
      limit: limit,
    );

    return result.map(SyncQueueItemModel.fromMap).toList();
  }

  Future<Map<String, int>> contarPorStatus() async {
    final db = await databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) AS total
      FROM sync_queue
      GROUP BY status
    ''');

    final resumo = {
      'pending': 0,
      'processing': 0,
      'synced': 0,
      'failed': 0,
      'conflict': 0,
    };

    for (final item in result) {
      final status = item['status']?.toString() ?? 'pending';
      resumo[status] = item['total'] as int? ?? 0;
    }

    return resumo;
  }

  Future<void> retryFailed() async {
    final db = await databaseHelper.database;
    await db.update(
      'sync_queue',
      {
        'status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
        'error_message': null,
      },
      where: 'status = ?',
      whereArgs: ['failed'],
    );
  }

  Future<void> marcarProcessando(String id) async {
    final db = await databaseHelper.database;
    await db.update(
      'sync_queue',
      {
        'status': 'processing',
        'last_attempt_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> marcarSincronizado(String id) async {
    final db = await databaseHelper.database;
    await db.update(
      'sync_queue',
      {
        'status': 'synced',
        'error_message': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> marcarFalha(SyncQueueItemModel item, Object error) async {
    final db = await databaseHelper.database;
    await db.update(
      'sync_queue',
      {
        'status': 'failed',
        'retry_count': item.retryCount + 1,
        'error_message': error.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }
}

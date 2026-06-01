import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../services/device_id_service.dart';
import 'sync_queue_repository.dart';

class AuditoriaRepository {
  final DatabaseHelper databaseHelper;
  final DeviceIdService deviceIdService;
  final SyncQueueRepository syncQueue;

  AuditoriaRepository({
    DatabaseHelper? databaseHelper,
    DeviceIdService? deviceIdService,
    SyncQueueRepository? syncQueue,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       deviceIdService = deviceIdService ?? const DeviceIdService(),
       syncQueue = syncQueue ?? SyncQueueRepository();

  Future<void> registrar({
    required String entityType,
    required String entityId,
    required String action,
    required String actorId,
    required String descricao,
    String? justificativa,
  }) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final deviceId = await deviceIdService.getDeviceId();

    final id = const Uuid().v4();
    final payload = {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'actor_id': actorId,
      'descricao': descricao,
      'justificativa': justificativa,
      'device_id': deviceId,
      'version': 1,
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
    };

    await db.insert(
      'auditoria_eventos',
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueue.enqueue(
      entityType: 'auditoria_eventos',
      entityId: id,
      operation: 'insert',
      payload: payload,
    );
  }
}

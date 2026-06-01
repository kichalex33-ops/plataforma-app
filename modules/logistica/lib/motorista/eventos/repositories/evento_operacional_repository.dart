import 'dart:convert';

import '../../../database/database_helper.dart';
import '../../../models/sync_queue_item_model.dart';
import '../../../repositories/sync_queue_repository.dart';
import '../models/evento_operacional_model.dart';

class EventoOperacionalRepository {
  static const entityType = 'motorista_evento_operacional';

  final DatabaseHelper databaseHelper;
  final SyncQueueRepository syncQueueRepository;

  EventoOperacionalRepository({
    DatabaseHelper? databaseHelper,
    SyncQueueRepository? syncQueueRepository,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       syncQueueRepository = syncQueueRepository ?? SyncQueueRepository();

  Future<void> salvar(EventoOperacionalModel evento) async {
    await syncQueueRepository.enqueue(
      entityType: entityType,
      entityId: evento.id,
      operation: 'create',
      payload: evento.toMap(),
    );
  }

  Future<List<EventoOperacionalModel>> listarPendentes() async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'sync_queue',
      where: 'entity_type = ? AND status IN (?, ?)',
      whereArgs: [entityType, 'pending', 'failed'],
      orderBy: 'created_at ASC',
    );

    return result.map(_fromQueueMap).toList();
  }

  Future<void> atualizarSyncStatus({
    required String eventoId,
    required String syncStatus,
  }) async {
    final db = await databaseHelper.database;
    await db.update(
      'sync_queue',
      {'status': syncStatus, 'updated_at': DateTime.now().toIso8601String()},
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, eventoId],
    );
  }

  EventoOperacionalModel _fromQueueMap(Map<String, Object?> map) {
    final item = SyncQueueItemModel.fromMap(map);
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    return EventoOperacionalModel.fromMap(
      payload,
    ).copyWith(syncStatus: item.status);
  }
}

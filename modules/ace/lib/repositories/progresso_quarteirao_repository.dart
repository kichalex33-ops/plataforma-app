import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/territorio_models.dart';
import '../services/device_id_service.dart';
import 'auditoria_repository.dart';
import 'quarteirao_repository.dart';
import 'sync_queue_repository.dart';

class ProgressoQuarteiraoRepository {
  final DatabaseHelper databaseHelper;
  final DeviceIdService deviceIdService;
  final SyncQueueRepository syncQueue;
  final AuditoriaRepository auditoria;
  final QuarteiraoRepository quarteiraoRepository;

  ProgressoQuarteiraoRepository({
    DatabaseHelper? databaseHelper,
    DeviceIdService? deviceIdService,
    SyncQueueRepository? syncQueue,
    AuditoriaRepository? auditoria,
    QuarteiraoRepository? quarteiraoRepository,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       deviceIdService = deviceIdService ?? const DeviceIdService(),
       syncQueue = syncQueue ?? SyncQueueRepository(),
       auditoria = auditoria ?? AuditoriaRepository(),
       quarteiraoRepository = quarteiraoRepository ?? QuarteiraoRepository();

  Future<ProgressoQuarteiraoModel> iniciar({
    required QuarteiraoOperacionalModel quarteirao,
    required String aceId,
    String? justificativa,
  }) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final deviceId = await deviceIdService.getDeviceId();
    final item = ProgressoQuarteiraoModel(
      sync: SyncFields(
        id: const Uuid().v4(),
        deviceId: deviceId,
        createdAt: now,
        updatedAt: now,
      ),
      quarteiraoId: quarteirao.sync.id,
      aceId: aceId,
      status: 'em_andamento',
      iniciadoEm: now,
      totalVisitados: 0,
      totalPendencias: 0,
      observacoes: justificativa ?? '',
    );

    await db.insert(
      'progresso_quarteirao',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueue.enqueue(
      entityType: 'progresso_quarteirao',
      entityId: item.sync.id,
      operation: 'upsert',
      payload: item.toMap(),
    );
    await quarteiraoRepository.atualizarStatus(
      quarteirao: quarteirao,
      status: 'em_andamento',
      actorId: aceId,
      justificativa: justificativa,
    );
    await auditoria.registrar(
      entityType: 'progresso_quarteirao',
      entityId: item.sync.id,
      action: 'iniciar',
      actorId: aceId,
      descricao: 'Quarteirao iniciado: ${quarteirao.codigo}',
      justificativa: justificativa,
    );

    return item;
  }

  Future<ProgressoQuarteiraoModel> concluir({
    required QuarteiraoOperacionalModel quarteirao,
    required String aceId,
    required int totalVisitados,
    required int totalPendencias,
    String observacoes = '',
  }) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final deviceId = await deviceIdService.getDeviceId();
    final item = ProgressoQuarteiraoModel(
      sync: SyncFields(
        id: const Uuid().v4(),
        deviceId: deviceId,
        createdAt: now,
        updatedAt: now,
      ),
      quarteiraoId: quarteirao.sync.id,
      aceId: aceId,
      status: 'concluido',
      concluidoEm: now,
      totalVisitados: totalVisitados,
      totalPendencias: totalPendencias,
      observacoes: observacoes,
    );
    final statusQuarteirao = totalPendencias > 0 ? 'pendente' : 'concluido';

    await db.transaction((txn) async {
      await txn.insert(
        'progresso_quarteirao',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.update(
        'quarteiroes_operacionais',
        {
          'status': statusQuarteirao,
          'total_visitados': totalVisitados,
          'total_pendencias': totalPendencias,
          'updated_at': now,
          'sync_status': 'pending',
        },
        where: 'id = ?',
        whereArgs: [quarteirao.sync.id],
      );
    });

    await syncQueue.enqueue(
      entityType: 'progresso_quarteirao',
      entityId: item.sync.id,
      operation: 'upsert',
      payload: item.toMap(),
    );
    await syncQueue.enqueue(
      entityType: 'quarteiroes_operacionais',
      entityId: quarteirao.sync.id,
      operation: 'upsert',
      payload: {
        ...quarteirao.toMap(),
        'status': statusQuarteirao,
        'total_visitados': totalVisitados,
        'total_pendencias': totalPendencias,
        'updated_at': now,
      },
    );
    await auditoria.registrar(
      entityType: 'progresso_quarteirao',
      entityId: item.sync.id,
      action: 'concluir',
      actorId: aceId,
      descricao: 'Quarteirao concluido: ${quarteirao.codigo}',
    );

    return item;
  }

  Future<List<ProgressoQuarteiraoModel>> listarPorQuarteirao(
    String quarteiraoId,
  ) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'progresso_quarteirao',
      where: 'quarteirao_id = ?',
      whereArgs: [quarteiraoId],
      orderBy: 'created_at DESC',
    );
    return result.map(ProgressoQuarteiraoModel.fromMap).toList();
  }
}

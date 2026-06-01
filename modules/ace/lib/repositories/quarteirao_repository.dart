import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/territorio_models.dart';
import '../services/device_id_service.dart';
import 'auditoria_repository.dart';
import 'sync_queue_repository.dart';

class QuarteiraoRepository {
  final DatabaseHelper databaseHelper;
  final DeviceIdService deviceIdService;
  final SyncQueueRepository syncQueue;
  final AuditoriaRepository auditoria;

  QuarteiraoRepository({
    DatabaseHelper? databaseHelper,
    DeviceIdService? deviceIdService,
    SyncQueueRepository? syncQueue,
    AuditoriaRepository? auditoria,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       deviceIdService = deviceIdService ?? const DeviceIdService(),
       syncQueue = syncQueue ?? SyncQueueRepository(),
       auditoria = auditoria ?? AuditoriaRepository();

  Future<QuarteiraoOperacionalModel> criar({
    required String setorId,
    required String municipioId,
    required String localidadeId,
    required String codigo,
    required int ordemExecucao,
    required int totalImoveisPrevistos,
    double? centroLatitude,
    double? centroLongitude,
    required String actorId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final deviceId = await deviceIdService.getDeviceId();
    final item = QuarteiraoOperacionalModel(
      sync: SyncFields(
        id: const Uuid().v4(),
        deviceId: deviceId,
        createdAt: now,
        updatedAt: now,
      ),
      setorId: setorId,
      municipioId: municipioId,
      localidadeId: localidadeId,
      codigo: codigo,
      ordemExecucao: ordemExecucao,
      status: 'nao_iniciado',
      totalImoveisPrevistos: totalImoveisPrevistos,
      totalVisitados: 0,
      totalFechados: 0,
      totalRecusas: 0,
      totalFocos: 0,
      totalPendencias: 0,
      centroLatitude: centroLatitude,
      centroLongitude: centroLongitude,
    );

    final db = await databaseHelper.database;
    await db.insert(
      'quarteiroes_operacionais',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueue.enqueue(
      entityType: 'quarteiroes_operacionais',
      entityId: item.sync.id,
      operation: 'upsert',
      payload: item.toMap(),
    );
    await auditoria.registrar(
      entityType: 'quarteiroes_operacionais',
      entityId: item.sync.id,
      action: 'criar',
      actorId: actorId,
      descricao: 'Quarteirao criado: $codigo',
    );

    return item;
  }

  Future<List<QuarteiraoOperacionalModel>> listarPorSetor(
    String setorId,
  ) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'quarteiroes_operacionais',
      where: 'setor_id = ?',
      whereArgs: [setorId],
      orderBy: 'ordem_execucao ASC, codigo ASC',
    );
    return result.map(QuarteiraoOperacionalModel.fromMap).toList();
  }

  Future<List<QuarteiraoOperacionalModel>> listarTodos({
    String? localidadeId,
    String? setorId,
  }) async {
    final db = await databaseHelper.database;
    String? where;
    List<Object?>? args;

    if (setorId != null) {
      where = 'setor_id = ?';
      args = [setorId];
    } else if (localidadeId != null) {
      where = 'localidade_id = ?';
      args = [localidadeId];
    }

    final result = await db.query(
      'quarteiroes_operacionais',
      where: where,
      whereArgs: args,
      orderBy: 'ordem_execucao ASC, codigo ASC',
    );
    return result.map(QuarteiraoOperacionalModel.fromMap).toList();
  }

  Future<void> atualizarStatus({
    required QuarteiraoOperacionalModel quarteirao,
    required String status,
    required String actorId,
    String? justificativa,
  }) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...quarteirao.toMap(),
      'status': status,
      'updated_at': now,
      'sync_status': 'pending',
    };

    await db.update(
      'quarteiroes_operacionais',
      payload,
      where: 'id = ?',
      whereArgs: [quarteirao.sync.id],
    );
    await syncQueue.enqueue(
      entityType: 'quarteiroes_operacionais',
      entityId: quarteirao.sync.id,
      operation: 'upsert',
      payload: payload,
    );
    await auditoria.registrar(
      entityType: 'quarteiroes_operacionais',
      entityId: quarteirao.sync.id,
      action: status,
      actorId: actorId,
      descricao: 'Status do quarteirao ${quarteirao.codigo}: $status',
      justificativa: justificativa,
    );
  }

  Future<void> reabrir({
    required QuarteiraoOperacionalModel quarteirao,
    required String actorId,
    required String justificativa,
  }) {
    return atualizarStatus(
      quarteirao: quarteirao,
      status: 'pendente',
      actorId: actorId,
      justificativa: justificativa,
    );
  }
}

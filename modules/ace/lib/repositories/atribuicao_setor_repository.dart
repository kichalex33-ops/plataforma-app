import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/territorio_models.dart';
import '../services/device_id_service.dart';
import 'auditoria_repository.dart';
import 'sync_queue_repository.dart';

class AtribuicaoSetorRepository {
  final DatabaseHelper databaseHelper;
  final DeviceIdService deviceIdService;
  final SyncQueueRepository syncQueue;
  final AuditoriaRepository auditoria;

  AtribuicaoSetorRepository({
    DatabaseHelper? databaseHelper,
    DeviceIdService? deviceIdService,
    SyncQueueRepository? syncQueue,
    AuditoriaRepository? auditoria,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       deviceIdService = deviceIdService ?? const DeviceIdService(),
       syncQueue = syncQueue ?? SyncQueueRepository(),
       auditoria = auditoria ?? AuditoriaRepository();

  Future<AtribuicaoSetorModel> atribuir({
    required String setorId,
    required String aceId,
    required String supervisorId,
    required String observacoes,
  }) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final deviceId = await deviceIdService.getDeviceId();
    final item = AtribuicaoSetorModel(
      sync: SyncFields(
        id: const Uuid().v4(),
        deviceId: deviceId,
        createdAt: now,
        updatedAt: now,
      ),
      setorId: setorId,
      aceId: aceId,
      supervisorId: supervisorId,
      dataInicio: now,
      status: 'ativa',
      observacoes: observacoes,
    );

    await db.insert(
      'atribuicoes_setor',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueue.enqueue(
      entityType: 'atribuicoes_setor',
      entityId: item.sync.id,
      operation: 'upsert',
      payload: item.toMap(),
    );
    await auditoria.registrar(
      entityType: 'atribuicoes_setor',
      entityId: item.sync.id,
      action: 'atribuir',
      actorId: supervisorId,
      descricao: 'Setor atribuido para $aceId',
    );

    return item;
  }

  Future<List<AtribuicaoSetorModel>> listarPorAce(String aceId) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'atribuicoes_setor',
      where: 'ace_id = ? AND status = ?',
      whereArgs: [aceId, 'ativa'],
      orderBy: 'data_inicio DESC',
    );
    return result.map(AtribuicaoSetorModel.fromMap).toList();
  }

  Future<List<AtribuicaoSetorModel>> listarPorSetor(String setorId) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'atribuicoes_setor',
      where: 'setor_id = ?',
      whereArgs: [setorId],
      orderBy: 'data_inicio DESC',
    );
    return result.map(AtribuicaoSetorModel.fromMap).toList();
  }
}

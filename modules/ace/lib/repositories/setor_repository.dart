import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/territorio_models.dart';
import '../services/device_id_service.dart';
import 'auditoria_repository.dart';
import 'sync_queue_repository.dart';

class SetorRepository {
  final DatabaseHelper databaseHelper;
  final DeviceIdService deviceIdService;
  final SyncQueueRepository syncQueue;
  final AuditoriaRepository auditoria;

  SetorRepository({
    DatabaseHelper? databaseHelper,
    DeviceIdService? deviceIdService,
    SyncQueueRepository? syncQueue,
    AuditoriaRepository? auditoria,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       deviceIdService = deviceIdService ?? const DeviceIdService(),
       syncQueue = syncQueue ?? SyncQueueRepository(),
       auditoria = auditoria ?? AuditoriaRepository();

  Future<SetorOperacionalModel> criarOuAtualizar({
    String? id,
    required String municipioId,
    required String localidadeId,
    required String codigo,
    required String nome,
    required String descricao,
    required String supervisorId,
    String status = 'planejado',
  }) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final deviceId = await deviceIdService.getDeviceId();
    final item = SetorOperacionalModel(
      sync: SyncFields(
        id: id ?? const Uuid().v4(),
        deviceId: deviceId,
        createdAt: now,
        updatedAt: now,
      ),
      municipioId: municipioId,
      localidadeId: localidadeId,
      codigo: codigo,
      nome: nome,
      descricao: descricao,
      supervisorId: supervisorId,
      status: status,
    );

    await db.insert(
      'setores_operacionais',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueue.enqueue(
      entityType: 'setores_operacionais',
      entityId: item.sync.id,
      operation: 'upsert',
      payload: item.toMap(),
    );
    await auditoria.registrar(
      entityType: 'setores_operacionais',
      entityId: item.sync.id,
      action: id == null ? 'criar' : 'editar',
      actorId: supervisorId,
      descricao: 'Setor salvo: $codigo - $nome',
    );

    return item;
  }

  Future<List<SetorOperacionalModel>> listarPorLocalidade(
    String localidadeId,
  ) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'setores_operacionais',
      where: 'localidade_id = ?',
      whereArgs: [localidadeId],
      orderBy: 'codigo ASC, nome ASC',
    );
    return result.map(SetorOperacionalModel.fromMap).toList();
  }

  Future<SetorOperacionalModel?> buscarPorId(String id) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'setores_operacionais',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return SetorOperacionalModel.fromMap(result.first);
  }
}

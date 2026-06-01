import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/territorio_models.dart';
import '../services/device_id_service.dart';
import 'auditoria_repository.dart';
import 'sync_queue_repository.dart';

class LocalidadeRepository {
  final DatabaseHelper databaseHelper;
  final DeviceIdService deviceIdService;
  final SyncQueueRepository syncQueue;
  final AuditoriaRepository auditoria;

  LocalidadeRepository({
    DatabaseHelper? databaseHelper,
    DeviceIdService? deviceIdService,
    SyncQueueRepository? syncQueue,
    AuditoriaRepository? auditoria,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       deviceIdService = deviceIdService ?? const DeviceIdService(),
       syncQueue = syncQueue ?? SyncQueueRepository(),
       auditoria = auditoria ?? AuditoriaRepository();

  Future<LocalidadeModel> criar({
    required String municipioId,
    required String nome,
    required String tipo,
    required String observacoes,
    required String actorId,
  }) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final deviceId = await deviceIdService.getDeviceId();
    final item = LocalidadeModel(
      sync: SyncFields(
        id: const Uuid().v4(),
        deviceId: deviceId,
        createdAt: now,
        updatedAt: now,
      ),
      municipioId: municipioId,
      nome: nome,
      tipo: tipo,
      observacoes: observacoes,
    );

    await db.insert(
      'localidades',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueue.enqueue(
      entityType: 'localidades',
      entityId: item.sync.id,
      operation: 'upsert',
      payload: item.toMap(),
    );
    await auditoria.registrar(
      entityType: 'localidades',
      entityId: item.sync.id,
      action: 'criar',
      actorId: actorId,
      descricao: 'Localidade criada: $nome',
    );

    return item;
  }

  Future<List<LocalidadeModel>> listar({String? municipioId}) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'localidades',
      where: municipioId == null ? null : 'municipio_id = ?',
      whereArgs: municipioId == null ? null : [municipioId],
      orderBy: 'nome ASC',
    );
    return result.map(LocalidadeModel.fromMap).toList();
  }
}

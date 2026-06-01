import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../database/database_helper.dart';
import '../../../repositories/sync_queue_repository.dart';
import '../../../services/device_id_service.dart';
import '../../sync/models/sync_metadata.dart';
import '../models/rastreamento_ponto_model.dart';

class RastreamentoRepository {
  final DatabaseHelper databaseHelper;
  final SyncQueueRepository syncQueueRepository;
  final DeviceIdService deviceIdService;

  RastreamentoRepository({
    DatabaseHelper? databaseHelper,
    SyncQueueRepository? syncQueueRepository,
    DeviceIdService? deviceIdService,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       syncQueueRepository = syncQueueRepository ?? SyncQueueRepository(),
       deviceIdService = deviceIdService ?? const DeviceIdService();

  Future<RastreamentoPontoModel> registrarPonto({
    required String municipioId,
    required String viagemId,
    required double latitude,
    required double longitude,
    double? velocidade,
    required String origemDado,
  }) async {
    final now = DateTime.now().toIso8601String();
    final ponto = RastreamentoPontoModel(
      sync: SyncMetadata(
        id: const Uuid().v4(),
        municipioId: municipioId,
        deviceId: await deviceIdService.getDeviceId(),
        createdAt: now,
        updatedAt: now,
      ),
      viagemId: viagemId,
      latitude: latitude,
      longitude: longitude,
      velocidade: velocidade,
      timestamp: now,
      origemDado: origemDado,
    );
    final payload = ponto.toMap();
    final db = await databaseHelper.database;
    await db.insert(
      'rastreamento_viagem',
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueueRepository.enqueue(
      entityType: 'rastreamento_viagem',
      entityId: ponto.sync.id,
      operation: 'upsert',
      payload: payload,
    );
    return ponto;
  }

  Future<List<RastreamentoPontoModel>> listarRecentes({int limit = 30}) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'rastreamento_viagem',
      orderBy: 'timestamp DESC, created_at DESC',
      limit: limit,
    );
    return result.map(RastreamentoPontoModel.fromMap).toList();
  }
}

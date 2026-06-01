import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../database/database_helper.dart';
import '../../../repositories/sync_queue_repository.dart';
import '../../../services/device_id_service.dart';
import '../../sync/models/sync_metadata.dart';
import '../models/medicamento_model.dart';

class FarmaciaRepository {
  final DatabaseHelper databaseHelper;
  final SyncQueueRepository syncQueueRepository;
  final DeviceIdService deviceIdService;

  FarmaciaRepository({
    DatabaseHelper? databaseHelper,
    SyncQueueRepository? syncQueueRepository,
    DeviceIdService? deviceIdService,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       syncQueueRepository = syncQueueRepository ?? SyncQueueRepository(),
       deviceIdService = deviceIdService ?? const DeviceIdService();

  Future<Map<String, int>> resumo() async {
    final db = await databaseHelper.database;
    return {
      'medicamentos': await _count(db, 'farmacia_medicamentos'),
      'estoque': await _sum(db, 'farmacia_estoque', 'quantidade'),
      'movimentacoes': await _count(db, 'farmacia_movimentacoes'),
      'alertas': await _countValidade(db),
    };
  }

  Future<List<MedicamentoModel>> listarMedicamentos() async {
    final db = await databaseHelper.database;
    final result = await db.query('farmacia_medicamentos', orderBy: 'nome ASC');
    return result.map(MedicamentoModel.fromMap).toList();
  }

  Future<MedicamentoModel> criarMedicamento({
    required String municipioId,
    required String nome,
    String? apresentacao,
    String? principioAtivo,
  }) async {
    final now = DateTime.now().toIso8601String();
    final medicamento = MedicamentoModel(
      sync: SyncMetadata(
        id: const Uuid().v4(),
        municipioId: municipioId,
        deviceId: await deviceIdService.getDeviceId(),
        createdAt: now,
        updatedAt: now,
      ),
      nome: nome,
      apresentacao: apresentacao,
      principioAtivo: principioAtivo,
    );
    final payload = medicamento.toMap();
    final db = await databaseHelper.database;
    await db.insert(
      'farmacia_medicamentos',
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueueRepository.enqueue(
      entityType: 'farmacia_medicamentos',
      entityId: medicamento.sync.id,
      operation: 'upsert',
      payload: payload,
    );
    return medicamento;
  }

  Future<int> _count(Database db, String table) async {
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM $table');
    return result.first['total'] as int? ?? 0;
  }

  Future<int> _sum(Database db, String table, String column) async {
    final result = await db.rawQuery(
      'SELECT SUM($column) AS total FROM $table',
    );
    return result.first['total'] as int? ?? 0;
  }

  Future<int> _countValidade(Database db) async {
    final limite = DateTime.now().add(const Duration(days: 60));
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM farmacia_estoque
      WHERE validade IS NOT NULL
        AND validade != ''
        AND validade <= ?
      ''',
      [limite.toIso8601String().substring(0, 10)],
    );
    return result.first['total'] as int? ?? 0;
  }
}

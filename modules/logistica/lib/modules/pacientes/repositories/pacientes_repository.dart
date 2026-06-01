import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../database/database_helper.dart';
import '../../../repositories/sync_queue_repository.dart';
import '../../../services/device_id_service.dart';
import '../../sync/models/sync_metadata.dart';
import '../models/paciente_model.dart';

class PacientesRepository {
  final DatabaseHelper databaseHelper;
  final SyncQueueRepository syncQueueRepository;
  final DeviceIdService deviceIdService;

  PacientesRepository({
    DatabaseHelper? databaseHelper,
    SyncQueueRepository? syncQueueRepository,
    DeviceIdService? deviceIdService,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       syncQueueRepository = syncQueueRepository ?? SyncQueueRepository(),
       deviceIdService = deviceIdService ?? const DeviceIdService();

  Future<int> contar() async {
    final db = await databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM pacientes');
    return result.first['total'] as int? ?? 0;
  }

  Future<List<PacienteModel>> listar() async {
    final db = await databaseHelper.database;
    final result = await db.query('pacientes', orderBy: 'nome ASC');
    return result.map(PacienteModel.fromMap).toList();
  }

  Future<PacienteModel> criar({
    required String municipioId,
    required String nome,
    String? telefone,
    String? endereco,
    double? latitude,
    double? longitude,
    String? necessidadesEspeciais,
  }) async {
    final now = DateTime.now().toIso8601String();
    final paciente = PacienteModel(
      sync: SyncMetadata(
        id: const Uuid().v4(),
        municipioId: municipioId,
        deviceId: await deviceIdService.getDeviceId(),
        createdAt: now,
        updatedAt: now,
      ),
      nome: nome,
      telefone: telefone,
      endereco: endereco,
      latitude: latitude,
      longitude: longitude,
      necessidadesEspeciais: necessidadesEspeciais,
    );
    final payload = paciente.toMap();
    final db = await databaseHelper.database;
    await db.insert(
      'pacientes',
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueueRepository.enqueue(
      entityType: 'pacientes',
      entityId: paciente.sync.id,
      operation: 'upsert',
      payload: payload,
    );
    return paciente;
  }
}

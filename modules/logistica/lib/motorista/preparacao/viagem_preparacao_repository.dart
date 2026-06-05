import 'package:sqflite/sqflite.dart';

import '../../auth/motorista_model.dart';
import '../../database/database_helper.dart';
import '../../motorista/eventos/services/evento_operacional_service.dart';
import '../../modules/transportes/models/viagem_model.dart';
import '../../repositories/sync_queue_repository.dart';
import 'models/viagem_preparacao_model.dart';
import 'viagem_preparacao_service.dart';

class ViagemPreparacaoRepository implements ViagemPreparacaoStore {
  final DatabaseHelper databaseHelper;
  final SyncQueueRepository syncQueueRepository;
  final EventoOperacionalService eventoService;

  ViagemPreparacaoRepository({
    DatabaseHelper? databaseHelper,
    SyncQueueRepository? syncQueueRepository,
    EventoOperacionalService? eventoService,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       syncQueueRepository = syncQueueRepository ?? SyncQueueRepository(),
       eventoService = eventoService ?? EventoOperacionalService();

  @override
  Future<void> salvarPreparacao(ViagemPreparacaoModel preparacao) async {
    final db = await databaseHelper.database;
    await db.insert(
      'viagem_preparacoes',
      preparacao.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueueRepository.enqueue(
      entityType: 'viagem_preparacoes',
      entityId: preparacao.id,
      operation: 'upsert',
      payload: preparacao.toMap(),
    );

    if (preparacao.checklist.isNotEmpty) {
      await db.insert('checklists', {
        'id': '${preparacao.id}-pre-uso',
        'municipio_id': preparacao.municipioId,
        'viagem_id': preparacao.viagemId,
        'motorista_id': preparacao.motoristaId,
        'tipo': 'pre_uso',
        'payload_json': preparacao.toMap()['checklist_payload_json'],
        'created_at': preparacao.horarioSaida ?? preparacao.horarioPreparacao,
        'sync_status': 'pending',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  @override
  Future<void> atualizarEstadoViagem({
    required ViagemModel viagem,
    required String statusOperacional,
    String? statusLegado,
    double? kmSaida,
    String? horarioSaidaConfirmada,
  }) async {
    final db = await databaseHelper.database;
    final payload = <String, Object?>{
      'status_operacional': statusOperacional,
      'sync_status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (statusLegado != null) payload['status'] = statusLegado;
    if (kmSaida != null) payload['km_saida'] = kmSaida;
    if (horarioSaidaConfirmada != null) {
      payload['horario_saida_confirmada'] = horarioSaidaConfirmada;
    }

    await db.update(
      'transportes_viagens',
      payload,
      where: 'id = ?',
      whereArgs: [viagem.sync.id],
    );
    await syncQueueRepository.enqueue(
      entityType: 'transportes_viagens',
      entityId: viagem.sync.id,
      operation: 'update',
      payload: {'id': viagem.sync.id, ...payload},
    );
  }

  @override
  Future<void> registrarEvento({
    required ViagemModel viagem,
    required MotoristaModel motorista,
    required String tipo,
    Map<String, dynamic> payload = const {},
  }) {
    return eventoService.registrar(
      viagem: viagem,
      motorista: motorista,
      tipo: tipo,
      payload: payload,
    );
  }
}

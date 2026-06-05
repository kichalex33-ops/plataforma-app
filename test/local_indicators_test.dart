import 'package:flutter_test/flutter_test.dart';
import 'package:plataforma_logistica/core/agents/agents.dart';
import 'package:plataforma_logistica/core/connectivity/models/connectivity_status.dart';
import 'package:plataforma_logistica/core/connectivity/services/connectivity_service.dart';
import 'package:plataforma_logistica/core/sync/models/sync_operation_type.dart';
import 'package:plataforma_logistica/core/sync/repositories/sync_queue_repository.dart';
import 'package:plataforma_logistica/core/sync/services/sync_queue_service.dart';
import 'package:plataforma_logistica/features/indicators/models/local_indicators.dart';
import 'package:plataforma_logistica/features/indicators/services/local_indicators_service.dart';
import 'package:plataforma_logistica_driver/core/logistica/logistica_enums.dart';
import 'package:plataforma_logistica_driver/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late InMemorySyncQueueRepository syncRepository;
  late AuditAgent auditAgent;
  late ConnectivityAgent connectivityAgent;
  late AppHealthAgent appHealthAgent;
  late LocalIndicatorsService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await _limparBancoLogistico(db);

    syncRepository = InMemorySyncQueueRepository();
    auditAgent = AuditAgent();
    connectivityAgent = ConnectivityAgent(
      service: ConnectivityService(initialStatus: ConnectivityStatus.offline),
    );
    appHealthAgent = AppHealthAgent(
      repository: syncRepository,
      auditAgent: auditAgent,
      connectivityAgent: connectivityAgent,
    );
    service = LocalIndicatorsService(
      appHealthAgent: appHealthAgent,
      auditAgent: auditAgent,
      reportAgent: ReportAgent(),
      validationAgent: ValidationAgent(),
    );
  });

  test('retorna indicadores zerados quando nao ha dados locais', () async {
    final indicators = await service.load();

    expect(indicators.totalViagens, 0);
    expect(indicators.viagensPendentes, 0);
    expect(indicators.passageirosTransportados, 0);
    expect(indicators.ocorrenciasRegistradas, 0);
    expect(indicators.checklistsConcluidos, 0);
    expect(indicators.itensPendentesSincronizacao, 0);
    expect(indicators.statusConexao, ConnectivityStatus.offline);
    expect(indicators.loadStatus, LocalIndicatorsLoadStatus.loaded);
    expect(auditAgent.events.last.type, AuditEventType.indicatorsViewed);
  });

  test(
    'calcula indicadores locais usando dados offline da logistica',
    () async {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime(2026, 6, 5).toIso8601String();

      await db.insert(
        'logistica_viagens',
        _base('viagem-pendente', now, {
          'origem': 'Base',
          'destino_principal': 'Unidade A',
          'data_consulta': now,
          'motorista_id_local': 'mot-1',
          'veiculo_id_local': 'vei-1',
          'status': StatusViagem.aguardando.dbValue,
          'prioridade': 'normal',
        }),
      );
      await db.insert(
        'logistica_viagens',
        _base('viagem-andamento', now, {
          'origem': 'Base',
          'destino_principal': 'Unidade B',
          'data_consulta': now,
          'motorista_id_local': 'mot-1',
          'veiculo_id_local': 'vei-1',
          'status': StatusViagem.emTransitoIda.dbValue,
          'prioridade': 'prioritaria',
        }),
      );
      await db.insert(
        'logistica_viagens',
        _base('viagem-concluida', now, {
          'origem': 'Base',
          'destino_principal': 'Unidade C',
          'data_consulta': now,
          'motorista_id_local': 'mot-1',
          'veiculo_id_local': 'vei-1',
          'status': StatusViagem.concluida.dbValue,
          'prioridade': 'normal',
        }),
      );
      await db.insert(
        'logistica_passageiros_viagem',
        _base('passageiro-1', now, {
          'viagem_id_local': 'viagem-concluida',
          'paciente_id_local': 'paciente-1',
          'status_ida': StatusPacienteIda.desembarcado.dbValue,
          'status_volta': StatusPacienteVolta.desembarcado.dbValue,
        }),
      );
      await db.insert(
        'logistica_ocorrencias',
        _base('ocorrencia-1', now, {
          'viagem_id_local': 'viagem-andamento',
          'motorista_id_local': 'mot-1',
          'tipo': TipoOcorrencia.paneMecanica.dbValue,
          'descricao': 'Teste',
          'data_hora': now,
        }),
      );
      await db.insert(
        'logistica_checklists',
        _base('checklist-1', now, {
          'viagem_id_local': 'viagem-andamento',
          'motorista_id_local': 'mot-1',
          'tipo': 'pre_uso',
          'payload_json': '{}',
          'concluido': 1,
        }),
      );
      await db.insert(
        'logistica_sync_items',
        _base('sync-local-1', now, {
          'tipo_evento': 'viagem_iniciada',
          'payload_json': '{}',
          'status_sync': StatusSync.pendente.dbValue,
        }),
      );

      final queueService = SyncQueueService(
        repository: syncRepository,
        dispatcher: (_) async {},
      );
      await queueService.enqueue(
        operationType: SyncOperationType.event,
        entityType: 'ocorrencia',
        entityId: 'ocorrencia-1',
        payload: {'tipo': 'pane_mecanica'},
      );

      await connectivityAgent.updateStatus(ConnectivityStatus.mobile);

      final indicators = await service.load();

      expect(indicators.totalViagens, 3);
      expect(indicators.viagensPendentes, 1);
      expect(indicators.viagensEmAndamento, 1);
      expect(indicators.viagensConcluidas, 1);
      expect(indicators.passageirosTransportados, 1);
      expect(indicators.ocorrenciasRegistradas, 1);
      expect(indicators.checklistsConcluidos, 1);
      expect(indicators.itensPendentesSincronizacao, 2);
      expect(indicators.statusConexao, ConnectivityStatus.mobile);
    },
  );

  test('atualizacao manual registra auditoria especifica', () async {
    await service.refresh();

    expect(auditAgent.events.last.type, AuditEventType.indicatorsRefreshed);
  });
}

Map<String, Object?> _base(String id, String now, Map<String, Object?> extra) {
  return {
    'id_local': id,
    'created_at': now,
    'updated_at': now,
    'status_sync': 'local',
    ...extra,
  };
}

Future<void> _limparBancoLogistico(dynamic db) async {
  for (final table in [
    'logistica_sync_items',
    'logistica_checklists',
    'logistica_ocorrencias',
    'logistica_passageiros_viagem',
    'logistica_viagens',
  ]) {
    await db.delete(table);
  }
}

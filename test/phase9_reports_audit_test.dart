import 'package:flutter_test/flutter_test.dart';
import 'package:plataforma_logistica/core/agents/agents.dart';
import 'package:plataforma_logistica/core/audit/models/audit_filter.dart';
import 'package:plataforma_logistica/core/audit/repositories/audit_log_repository.dart';
import 'package:plataforma_logistica/core/audit/services/audit_log_service.dart';
import 'package:plataforma_logistica/core/connectivity/models/connectivity_status.dart';
import 'package:plataforma_logistica/core/connectivity/services/connectivity_service.dart';
import 'package:plataforma_logistica/core/sync/models/sync_operation_type.dart';
import 'package:plataforma_logistica/core/sync/repositories/sync_queue_repository.dart';
import 'package:plataforma_logistica/core/sync/services/sync_queue_service.dart';
import 'package:plataforma_logistica/features/indicators/models/local_indicators.dart';
import 'package:plataforma_logistica/features/indicators/services/local_indicators_service.dart';
import 'package:plataforma_logistica/features/reports/models/report_filter.dart';
import 'package:plataforma_logistica/features/reports/services/local_report_service.dart';

void main() {
  late InMemoryAuditLogRepository auditRepository;
  late AuditLogService auditService;
  late AuditAgent auditAgent;
  late InMemorySyncQueueRepository syncRepository;
  late ConnectivityAgent connectivityAgent;
  late AppHealthAgent appHealthAgent;

  setUp(() {
    auditRepository = InMemoryAuditLogRepository();
    auditService = AuditLogService(repository: auditRepository);
    auditAgent = AuditAgent(logService: auditService);
    syncRepository = InMemorySyncQueueRepository();
    connectivityAgent = ConnectivityAgent(
      service: ConnectivityService(initialStatus: ConnectivityStatus.offline),
    );
    appHealthAgent = AppHealthAgent(
      repository: syncRepository,
      auditAgent: auditAgent,
      connectivityAgent: connectivityAgent,
    );
  });

  test('AuditAgent registra evento estruturado sem dados sensiveis', () async {
    await auditAgent.record(
      type: AuditEventType.login,
      description: 'Login Alex CPF 123.456.789-00 senha 1234 token abc',
      origin: 'login',
      severity: AuditSeverity.info,
      metadata: {
        'cpf': '123.456.789-00',
        'senha': '1234',
        'token': 'abc',
        'motorista': 'Alex',
      },
    );

    final logs = await auditRepository.list();
    final log = logs.single;

    expect(log.type, AuditEventType.login);
    expect(log.description, isNot(contains('123.456.789-00')));
    expect(log.description, isNot(contains('1234')));
    expect(log.description, isNot(contains('abc')));
    expect(log.metadataJson, isNot(contains('cpf')));
    expect(log.metadataJson, isNot(contains('senha')));
    expect(log.metadataJson, isNot(contains('token')));
    expect(log.metadataJson, contains('Alex'));
  });

  test('repositorio de auditoria filtra por data, tipo e severidade', () async {
    final older = DateTime(2026, 6, 1, 8);
    final newer = DateTime(2026, 6, 5, 9);

    await auditService.record(
      type: AuditEventType.appOpened,
      description: 'App aberto',
      origin: 'app',
      severity: AuditSeverity.info,
      createdAt: older,
    );
    await auditService.record(
      type: AuditEventType.syncFailed,
      description: 'Falha de sincronizacao',
      origin: 'sync',
      severity: AuditSeverity.error,
      createdAt: newer,
    );

    final filtered = await auditRepository.list(
      filter: AuditFilter(
        start: DateTime(2026, 6, 5),
        end: DateTime(2026, 6, 6),
        type: AuditEventType.syncFailed,
        severity: AuditSeverity.error,
      ),
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.type, AuditEventType.syncFailed);
  });

  test('relatorios locais reaproveitam indicadores da fase 8', () async {
    final queueService = SyncQueueService(
      repository: syncRepository,
      dispatcher: (_) async {},
    );
    await queueService.enqueue(
      operationType: SyncOperationType.event,
      entityType: 'viagem',
      entityId: 'viagem-1',
      payload: {'status': 'concluida'},
    );

    final indicatorsService = _FakeIndicatorsService(
      appHealthAgent: appHealthAgent,
      auditAgent: auditAgent,
      reportAgent: ReportAgent(),
      validationAgent: ValidationAgent(),
    );
    final reportService = LocalReportService(
      reportAgent: ReportAgent(),
      validationAgent: ValidationAgent(),
      appHealthAgent: appHealthAgent,
      indicatorsService: indicatorsService,
    );

    final report = await reportService.generate(
      const ReportFilter(title: 'Resumo local'),
    );

    expect(report.title, 'Resumo local');
    expect(
      report.sections.map((section) => section.title),
      contains('Viagens'),
    );
    expect(
      report.sections.map((section) => section.title),
      contains('Saude local'),
    );
    expect(report.total('total_viagens'), 1);
    expect(report.total('passageiros_transportados'), 1);
    expect(report.total('pendencias_sync'), 1);
  });
}

class _FakeIndicatorsService extends LocalIndicatorsService {
  _FakeIndicatorsService({
    required super.appHealthAgent,
    required super.auditAgent,
    required super.reportAgent,
    required super.validationAgent,
  });

  @override
  Future<LocalIndicators> refresh() async {
    final health = await appHealthAgent.snapshot();
    return LocalIndicators(
      totalViagens: 1,
      viagensPendentes: 0,
      viagensEmAndamento: 0,
      viagensConcluidas: 1,
      passageirosTransportados: 1,
      ocorrenciasRegistradas: 0,
      checklistsConcluidos: 0,
      itensPendentesSincronizacao: health.pendingItems,
      ultimaSincronizacao: health.lastSuccessfulSync,
      statusConexao: health.connectivityStatus,
      statusSincronizacao: health.status,
      errosRecentes: health.recentErrors,
      loadStatus: LocalIndicatorsLoadStatus.loaded,
    );
  }
}

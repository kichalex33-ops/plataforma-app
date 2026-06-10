import 'package:plataforma_logistica/core/agents/agents.dart';
import 'package:plataforma_logistica/core/connectivity/models/connectivity_status.dart';
import 'package:plataforma_logistica/core/connectivity/services/connectivity_service.dart';
import 'package:plataforma_logistica/core/sync/models/sync_operation_type.dart';
import 'package:plataforma_logistica/core/sync/models/sync_status.dart';
import 'package:plataforma_logistica/core/sync/repositories/sync_queue_repository.dart';
import 'package:plataforma_logistica/core/sync/repositories/sqlite_sync_queue_repository.dart';
import 'package:plataforma_logistica/core/sync/services/api_sync_dispatcher.dart';
import 'package:plataforma_logistica/core/sync/services/sync_queue_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plataforma_logistica_driver/database/database_helper.dart';
import 'package:plataforma_logistica_driver/motorista/sync/driver_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Fase 7 - agentes de sincronizacao', () {
    late InMemorySyncQueueRepository repository;
    late ConnectivityService connectivityService;
    late ConnectivityAgent connectivityAgent;
    late AuditAgent auditAgent;

    SyncAgent buildSyncAgent({
      Future<void> Function(dynamic item)? dispatcher,
      ConnectivityStatus status = ConnectivityStatus.offline,
    }) {
      repository = InMemorySyncQueueRepository();
      connectivityService = ConnectivityService(initialStatus: status);
      connectivityAgent = ConnectivityAgent(service: connectivityService);
      auditAgent = AuditAgent();

      final queueService = SyncQueueService(
        repository: repository,
        dispatcher: dispatcher ?? (_) async {},
      );

      return SyncAgent(
        queueService: queueService,
        connectivityAgent: connectivityAgent,
        auditAgent: auditAgent,
      );
    }

    test('salva evento pendente localmente quando esta offline', () async {
      final syncAgent = buildSyncAgent(status: ConnectivityStatus.offline);

      final item = await syncAgent.registerEvent(
        operationType: SyncOperationType.create,
        entityType: 'viagem',
        entityId: 'viagem-1',
        payload: {'status': 'saida_confirmada'},
      );

      expect(item.status, SyncStatus.pending);
      expect(await repository.unsyncedCount(), 1);

      final result = await syncAgent.syncNow();

      expect(result.sent, 0);
      expect(result.failed, 0);
      expect(await repository.unsyncedCount(), 1);
      expect(auditAgent.events.last.type, AuditEventType.syncSkipped);
    });

    test('sincroniza pendentes quando conexao volta', () async {
      final sent = <String>[];
      final syncAgent = buildSyncAgent(
        status: ConnectivityStatus.offline,
        dispatcher: (item) async => sent.add(item.id as String),
      );

      await syncAgent.registerEvent(
        operationType: SyncOperationType.event,
        entityType: 'ocorrencia',
        entityId: 'ocorrencia-1',
        payload: {'tipo': 'panico'},
      );

      await connectivityAgent.updateStatus(ConnectivityStatus.mobile);

      expect(sent, hasLength(1));
      expect(await repository.unsyncedCount(), 0);
      expect((await repository.listAll()).single.status, SyncStatus.synced);
      expect(syncAgent.lastSuccessfulSync, isNotNull);
      expect(auditAgent.events.last.type, AuditEventType.syncCompleted);
    });

    test('mantem item local e registra erro quando envio falha', () async {
      final syncAgent = buildSyncAgent(
        status: ConnectivityStatus.wifi,
        dispatcher: (_) async => throw Exception('servidor indisponivel'),
      );

      await syncAgent.registerEvent(
        operationType: SyncOperationType.update,
        entityType: 'passageiro',
        entityId: 'passageiro-1',
        payload: {'status': 'ausente'},
      );

      final result = await syncAgent.syncNow();
      final item = (await repository.listAll()).single;

      expect(result.failed, 1);
      expect(item.status, SyncStatus.failed);
      expect(item.attempts, 1);
      expect(item.error, contains('servidor indisponivel'));
      expect(await repository.unsyncedCount(), 1);
      expect(auditAgent.events.last.type, AuditEventType.syncFailed);
    });

    test(
      'app health informa pendencias, ultimo sync e erros recentes',
      () async {
        final failingAgent = buildSyncAgent(
          status: ConnectivityStatus.wifi,
          dispatcher: (_) async => throw Exception('timeout 4G'),
        );

        await failingAgent.registerEvent(
          operationType: SyncOperationType.gps,
          entityType: 'localizacao',
          entityId: 'gps-1',
          payload: {'lat': -23.0, 'lng': -46.0},
        );
        await failingAgent.syncNow();

        final health = AppHealthAgent(
          repository: repository,
          auditAgent: auditAgent,
          connectivityAgent: connectivityAgent,
        );

        final snapshot = await health.snapshot();

        expect(snapshot.pendingItems, 1);
        expect(snapshot.status, SyncStatus.failed);
        expect(snapshot.recentErrors.single, contains('timeout 4G'));
        expect(snapshot.connectivityStatus, ConnectivityStatus.wifi);

        final successAgent = buildSyncAgent(status: ConnectivityStatus.wifi);
        await successAgent.registerEvent(
          operationType: SyncOperationType.create,
          entityType: 'viagem',
          entityId: 'viagem-2',
          payload: {'status': 'concluida'},
        );
        await successAgent.syncNow();

        final successHealth = AppHealthAgent(
          repository: repository,
          auditAgent: auditAgent,
          connectivityAgent: connectivityAgent,
        );

        final successSnapshot = await successHealth.snapshot();

        expect(successSnapshot.pendingItems, 0);
        expect(successSnapshot.status, SyncStatus.synced);
        expect(successSnapshot.lastSuccessfulSync, isNotNull);
      },
    );

    test('repositorio local preserva fila entre instancias', () async {
      final firstRepository = SQLiteSyncQueueRepository();
      await firstRepository.listAll();
      final db = await DatabaseHelper.instance.database;
      await db.delete(SQLiteSyncQueueRepository.table);
      final firstService = SyncQueueService(
        repository: firstRepository,
        dispatcher: (_) async {},
      );

      await firstService.enqueue(
        operationType: SyncOperationType.event,
        entityType: 'viagem',
        entityId: 'viagem-local',
        payload: {'acao': 'offline'},
      );

      final secondRepository = SQLiteSyncQueueRepository();

      expect(await secondRepository.unsyncedCount(), 1);
      expect(
        (await secondRepository.listAll()).single.entityId,
        'viagem-local',
      );
    });

    test('limita tentativas de reenvio controlado', () async {
      final repository = InMemorySyncQueueRepository();
      final service = SyncQueueService(
        repository: repository,
        maxAttempts: 2,
        dispatcher: (_) async => throw Exception('api fora'),
      );

      await service.enqueue(
        operationType: SyncOperationType.event,
        entityType: 'viagem',
        entityId: 'viagem-retry',
        payload: {'status': 'pendente'},
      );

      await service.syncPending(canSync: true);
      await service.syncPending(canSync: true);
      final third = await service.syncPending(canSync: true);

      final item = (await repository.listAll()).single;
      expect(item.attempts, 2);
      expect(third.attempted, 0);
      expect(item.error, contains('MAX_TENTATIVAS'));
    });

    test(
      'conflito de API marca item para revisao sem apagar dado local',
      () async {
        final repository = InMemorySyncQueueRepository();
        final service = SyncQueueService(
          repository: repository,
          maxAttempts: 5,
          dispatcher: (_) async =>
              throw const SyncConflictException('versao antiga'),
        );

        await service.enqueue(
          operationType: SyncOperationType.update,
          entityType: 'viagem',
          entityId: 'viagem-conflito',
          payload: {'versao': 1},
        );

        final result = await service.syncPending(canSync: true);
        final item = (await repository.listAll()).single;

        expect(result.failed, 1);
        expect(item.status, SyncStatus.failed);
        expect(item.attempts, 5);
        expect(item.error, contains('CONFLITO'));
        expect(item.payload['versao'], 1);
      },
    );
  });

  group('Indicador de sincronizacao do motorista', () {
    test('exibe pendencias no resumo operacional', () {
      const status = DriverSyncStatus(
        online: true,
        enviados: 2,
        falhas: 0,
        pendentes: 3,
        ultimoSync: '03/06/2026 10:30',
      );

      expect(status.resumoSync, contains('Pendentes: 3'));
    });
  });
}

import 'dart:async';

import '../audit/models/audit_event_type.dart';
import '../audit/models/audit_severity.dart';
import '../audit/services/audit_log_service.dart';
import '../sync/models/sync_queue_item.dart';

class AuditEvent {
  final String id;
  final AuditEventType type;
  final String message;
  final String? itemId;
  final DateTime createdAt;
  final AuditSeverity severity;
  final String origin;

  AuditEvent({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.itemId,
    this.severity = AuditSeverity.info,
    this.origin = 'app',
  });
}

class AuditAgent {
  final AuditLogService? logService;
  final List<AuditEvent> _events = <AuditEvent>[];

  AuditAgent({this.logService});

  List<AuditEvent> get events => List<AuditEvent>.unmodifiable(_events);

  Future<void> record({
    required AuditEventType type,
    required String description,
    required String origin,
    AuditSeverity severity = AuditSeverity.info,
    String? entityType,
    String? entityId,
    Map<String, Object?> metadata = const {},
    DateTime? createdAt,
  }) async {
    final service = logService;
    if (service != null) {
      final log = await service.record(
        type: type,
        description: description,
        origin: origin,
        severity: severity,
        entityType: entityType,
        entityId: entityId,
        metadata: metadata,
        createdAt: createdAt,
      );
      _events.add(
        AuditEvent(
          id: log.id,
          type: log.type,
          message: log.description,
          itemId: entityId,
          createdAt: log.createdAt,
          severity: log.severity,
          origin: log.origin,
        ),
      );
      return;
    }

    _events.add(
      AuditEvent(
        id: SyncQueueItem.createSecureLocalId(),
        type: type,
        message: description,
        itemId: entityId,
        createdAt: createdAt ?? DateTime.now(),
        severity: severity,
        origin: origin,
      ),
    );
  }

  void registerAttempt({String? message}) {
    _add(
      AuditEventType.syncAttempt,
      message ?? 'Tentativa de sincronizacao iniciada.',
      origin: 'sync',
    );
  }

  void registerCompleted({String? message}) {
    _add(
      AuditEventType.syncCompleted,
      message ?? 'Sincronizacao concluida.',
      origin: 'sync',
    );
  }

  void registerFailure({required String error, String? itemId}) {
    _add(
      AuditEventType.syncFailed,
      'Falha de sincronizacao: $error',
      itemId: itemId,
      origin: 'sync',
      severity: AuditSeverity.error,
    );
  }

  void registerSkipped({String? message}) {
    _add(
      AuditEventType.syncSkipped,
      message ?? 'Sincronizacao ignorada por falta de conexao segura.',
      origin: 'sync',
      severity: AuditSeverity.warning,
    );
  }

  void registerIndicatorsViewed({String? message}) {
    _add(
      AuditEventType.indicatorsViewed,
      message ?? 'Tela de indicadores locais acessada.',
      origin: 'indicators',
    );
  }

  void registerIndicatorsRefreshed({String? message}) {
    _add(
      AuditEventType.indicatorsRefreshed,
      message ?? 'Indicadores locais atualizados manualmente.',
      origin: 'indicators',
    );
  }

  void registerReportViewed({String? message}) {
    _add(
      AuditEventType.reportViewed,
      message ?? 'Tela de relatorios locais acessada.',
      origin: 'reports',
    );
  }

  void registerReportGenerated({String? message}) {
    _add(
      AuditEventType.reportGenerated,
      message ?? 'Relatorio local consolidado.',
      origin: 'reports',
    );
  }

  void _add(
    AuditEventType type,
    String message, {
    String? itemId,
    String origin = 'app',
    AuditSeverity severity = AuditSeverity.info,
  }) {
    final event = AuditEvent(
      id: SyncQueueItem.createSecureLocalId(),
      type: type,
      message: message,
      itemId: itemId,
      createdAt: DateTime.now(),
      severity: severity,
      origin: origin,
    );
    _events.add(event);

    final service = logService;
    if (service != null) {
      unawaited(
        service.record(
          type: type,
          description: message,
          origin: origin,
          severity: severity,
          entityId: itemId,
        ),
      );
    }
  }
}

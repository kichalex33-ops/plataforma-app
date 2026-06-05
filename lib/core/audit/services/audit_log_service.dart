import 'dart:convert';

import '../../sync/models/sync_queue_item.dart';
import '../models/audit_event_type.dart';
import '../models/audit_log.dart';
import '../models/audit_severity.dart';
import '../repositories/audit_log_repository.dart';

class AuditLogService {
  final AuditLogRepository repository;

  AuditLogService({required this.repository});

  Future<AuditLog> record({
    required AuditEventType type,
    required String description,
    required String origin,
    AuditSeverity severity = AuditSeverity.info,
    String? entityType,
    String? entityId,
    Map<String, Object?> metadata = const {},
    DateTime? createdAt,
    String syncStatus = 'local',
  }) async {
    final log = AuditLog(
      id: SyncQueueItem.createSecureLocalId(),
      type: type,
      severity: severity,
      description: _sanitizeDescription(description),
      origin: _safeText(origin, fallback: 'app'),
      entityType: _safeTextOrNull(entityType),
      entityId: _safeTextOrNull(entityId),
      metadataJson: jsonEncode(_sanitizeMetadata(metadata)),
      syncStatus: syncStatus,
      createdAt: createdAt ?? DateTime.now(),
    );
    await repository.save(log);
    return log;
  }

  String _sanitizeDescription(String value) {
    var sanitized = value;
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b'),
      '[cpf-removido]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'(senha|password)\s*[:=]?\s*\S+', caseSensitive: false),
      r'$1 [removido]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'(token)\s*[:=]?\s*\S+', caseSensitive: false),
      r'$1 [removido]',
    );
    return sanitized.trim();
  }

  Map<String, Object?> _sanitizeMetadata(Map<String, Object?> metadata) {
    final result = <String, Object?>{};
    for (final entry in metadata.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('senha') ||
          key.contains('password') ||
          key.contains('token') ||
          key == 'cpf' ||
          key.endsWith('_cpf')) {
        continue;
      }
      result[entry.key] = entry.value;
    }
    return result;
  }

  String _safeText(String value, {required String fallback}) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String? _safeTextOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

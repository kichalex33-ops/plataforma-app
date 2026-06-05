import 'audit_event_type.dart';
import 'audit_severity.dart';

class AuditLog {
  final String id;
  final AuditEventType type;
  final AuditSeverity severity;
  final String description;
  final String origin;
  final String? entityType;
  final String? entityId;
  final String metadataJson;
  final String syncStatus;
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.origin,
    required this.metadataJson,
    required this.syncStatus,
    required this.createdAt,
    this.entityType,
    this.entityId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'severity': severity.value,
      'description': description,
      'origin': origin,
      'entityType': entityType,
      'entityId': entityId,
      'metadataJson': metadataJson,
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id']?.toString() ?? '',
      type: AuditEventTypeLabel.parse(json['type']?.toString()),
      severity: AuditSeverityLabel.parse(json['severity']?.toString()),
      description: json['description']?.toString() ?? '',
      origin: json['origin']?.toString() ?? 'app',
      entityType: json['entityType']?.toString(),
      entityId: json['entityId']?.toString(),
      metadataJson: json['metadataJson']?.toString() ?? '{}',
      syncStatus: json['syncStatus']?.toString() ?? 'local',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

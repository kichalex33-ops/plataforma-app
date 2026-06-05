import 'audit_event_type.dart';
import 'audit_severity.dart';

class AuditFilter {
  final DateTime? start;
  final DateTime? end;
  final AuditEventType? type;
  final AuditSeverity? severity;

  const AuditFilter({this.start, this.end, this.type, this.severity});
}

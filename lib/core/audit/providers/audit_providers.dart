import 'package:flutter/foundation.dart';

import '../models/audit_filter.dart';
import '../models/audit_log.dart';
import '../repositories/audit_log_repository.dart';
import '../services/audit_log_service.dart';

final auditLogRepositoryProvider = SharedPreferencesAuditLogRepository();

final auditLogServiceProvider = AuditLogService(
  repository: auditLogRepositoryProvider,
);

class AuditHistoryState {
  final bool loading;
  final List<AuditLog> logs;
  final String? error;

  const AuditHistoryState({
    required this.loading,
    required this.logs,
    this.error,
  });

  const AuditHistoryState.loading()
    : loading = true,
      logs = const [],
      error = null;

  const AuditHistoryState.loaded(this.logs) : loading = false, error = null;

  const AuditHistoryState.error(String message)
    : loading = false,
      logs = const [],
      error = message;
}

class AuditHistoryController extends ChangeNotifier {
  final AuditLogRepository repository;

  AuditHistoryController({required this.repository});

  AuditHistoryState _state = const AuditHistoryState.loading();

  AuditHistoryState get state => _state;

  Future<void> load({AuditFilter? filter}) async {
    _state = const AuditHistoryState.loading();
    notifyListeners();
    try {
      _state = AuditHistoryState.loaded(await repository.list(filter: filter));
    } catch (error) {
      _state = AuditHistoryState.error(error.toString());
    }
    notifyListeners();
  }
}

AuditHistoryController buildAuditHistoryController() {
  return AuditHistoryController(repository: auditLogRepositoryProvider);
}

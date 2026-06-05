import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/audit_filter.dart';
import '../models/audit_log.dart';

abstract class AuditLogRepository {
  Future<void> save(AuditLog log);

  Future<List<AuditLog>> list({AuditFilter? filter, int limit = 100});

  Future<List<AuditLog>> recentErrors({int limit = 5});
}

class InMemoryAuditLogRepository implements AuditLogRepository {
  final List<AuditLog> _logs = <AuditLog>[];

  @override
  Future<void> save(AuditLog log) async {
    final index = _logs.indexWhere((item) => item.id == log.id);
    if (index >= 0) {
      _logs[index] = log;
    } else {
      _logs.add(log);
    }
  }

  @override
  Future<List<AuditLog>> list({AuditFilter? filter, int limit = 100}) async {
    return _applyFilter(_logs, filter).take(limit).toList(growable: false);
  }

  @override
  Future<List<AuditLog>> recentErrors({int limit = 5}) async {
    return _logs
        .where(
          (log) =>
              log.severity.name == 'error' || log.severity.name == 'critical',
        )
        .toList(growable: false)
        .reversed
        .take(limit)
        .toList(growable: false);
  }
}

class SharedPreferencesAuditLogRepository implements AuditLogRepository {
  final String storageKey;

  const SharedPreferencesAuditLogRepository({
    this.storageKey = 'local_audit_logs',
  });

  @override
  Future<void> save(AuditLog log) async {
    final logs = await _load();
    final index = logs.indexWhere((item) => item.id == log.id);
    if (index >= 0) {
      logs[index] = log;
    } else {
      logs.add(log);
    }
    await _persist(logs);
  }

  @override
  Future<List<AuditLog>> list({AuditFilter? filter, int limit = 100}) async {
    return _applyFilter(
      await _load(),
      filter,
    ).take(limit).toList(growable: false);
  }

  @override
  Future<List<AuditLog>> recentErrors({int limit = 5}) async {
    return (await _load())
        .where(
          (log) =>
              log.severity.name == 'error' || log.severity.name == 'critical',
        )
        .toList(growable: false)
        .reversed
        .take(limit)
        .toList(growable: false);
  }

  Future<List<AuditLog>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return <AuditLog>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <AuditLog>[];
    return decoded
        .whereType<Map>()
        .map((item) => AuditLog.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: true);
  }

  Future<void> _persist(List<AuditLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(logs.map((log) => log.toJson()).toList()),
    );
  }
}

Iterable<AuditLog> _applyFilter(List<AuditLog> logs, AuditFilter? filter) {
  var result = logs.toList(growable: false)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (filter == null) return result;
  if (filter.start != null) {
    result = result
        .where((log) => !log.createdAt.isBefore(filter.start!))
        .toList(growable: false);
  }
  if (filter.end != null) {
    result = result
        .where((log) => !log.createdAt.isAfter(filter.end!))
        .toList(growable: false);
  }
  if (filter.type != null) {
    result = result
        .where((log) => log.type == filter.type)
        .toList(growable: false);
  }
  if (filter.severity != null) {
    result = result
        .where((log) => log.severity == filter.severity)
        .toList(growable: false);
  }
  return result;
}

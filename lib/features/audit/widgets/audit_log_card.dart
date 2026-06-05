import 'package:flutter/material.dart';

import '../../../core/audit/models/audit_event_type.dart';
import '../../../core/audit/models/audit_log.dart';
import '../../../core/audit/models/audit_severity.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class AuditLogCard extends StatelessWidget {
  final AuditLog log;

  const AuditLogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.history, color: _color(log.severity)),
        title: Text(log.type.label),
        subtitle: Text(
          '${log.description}\n${_format(log.createdAt)} | ${log.origin} | ${log.syncStatus}',
        ),
        isThreeLine: true,
        trailing: Text(
          log.severity.label,
          style: TextStyle(
            color: _color(log.severity),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.sm),
      ),
    );
  }

  Color _color(AuditSeverity severity) {
    return switch (severity) {
      AuditSeverity.info => AppColors.navy,
      AuditSeverity.warning => Colors.orange.shade800,
      AuditSeverity.error => Colors.red.shade700,
      AuditSeverity.critical => Colors.red.shade900,
    };
  }

  String _format(DateTime value) {
    String two(int input) => input.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }
}

import 'package:flutter/material.dart';

import '../../../core/audit/models/audit_event_type.dart';
import '../../../core/audit/models/audit_filter.dart';
import '../../../core/audit/models/audit_severity.dart';
import '../../../core/theme/app_spacing.dart';

class AuditFilterBar extends StatefulWidget {
  final ValueChanged<AuditFilter> onChanged;

  const AuditFilterBar({super.key, required this.onChanged});

  @override
  State<AuditFilterBar> createState() => _AuditFilterBarState();
}

class _AuditFilterBarState extends State<AuditFilterBar> {
  AuditEventType? _type;
  AuditSeverity? _severity;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        DropdownButton<AuditEventType?>(
          value: _type,
          hint: const Text('Tipo'),
          items: [
            const DropdownMenuItem<AuditEventType?>(
              value: null,
              child: Text('Todos'),
            ),
            ...AuditEventType.values.map(
              (type) => DropdownMenuItem<AuditEventType?>(
                value: type,
                child: Text(type.label),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _type = value);
            _emit();
          },
        ),
        DropdownButton<AuditSeverity?>(
          value: _severity,
          hint: const Text('Severidade'),
          items: [
            const DropdownMenuItem<AuditSeverity?>(
              value: null,
              child: Text('Todas'),
            ),
            ...AuditSeverity.values.map(
              (severity) => DropdownMenuItem<AuditSeverity?>(
                value: severity,
                child: Text(severity.label),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _severity = value);
            _emit();
          },
        ),
      ],
    );
  }

  void _emit() {
    widget.onChanged(AuditFilter(type: _type, severity: _severity));
  }
}

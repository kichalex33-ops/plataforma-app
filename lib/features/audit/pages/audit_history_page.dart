import 'package:flutter/material.dart';

import '../../../core/audit/models/audit_filter.dart';
import '../../../core/audit/providers/audit_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../widgets/audit_filter_bar.dart';
import '../widgets/audit_log_card.dart';

class AuditHistoryPage extends StatefulWidget {
  final AuditHistoryController? controller;

  const AuditHistoryPage({super.key, this.controller});

  @override
  State<AuditHistoryPage> createState() => _AuditHistoryPageState();
}

class _AuditHistoryPageState extends State<AuditHistoryPage> {
  late final AuditHistoryController _controller =
      widget.controller ?? buildAuditHistoryController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _filter(AuditFilter filter) {
    _controller.load(filter: filter);
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Auditoria Local')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AuditFilterBar(onChanged: _filter),
          const SizedBox(height: AppSpacing.md),
          if (state.loading)
            const Center(child: CircularProgressIndicator())
          else if (state.error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: const Text('Erro ao carregar auditoria'),
                subtitle: Text(state.error!),
              ),
            )
          else if (state.logs.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.history),
                title: Text('Nenhum evento local encontrado'),
                subtitle: Text(
                  'Os eventos serao exibidos conforme o uso do app.',
                ),
              ),
            )
          else
            for (final log in state.logs) AuditLogCard(log: log),
        ],
      ),
    );
  }
}

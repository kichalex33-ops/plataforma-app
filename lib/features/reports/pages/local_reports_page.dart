import 'package:flutter/material.dart';

import '../../../core/sync/providers/sync_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/report_filter.dart';
import '../providers/local_report_providers.dart';
import '../widgets/report_summary_card.dart';

class LocalReportsPage extends StatefulWidget {
  final LocalReportController? controller;

  const LocalReportsPage({super.key, this.controller});

  @override
  State<LocalReportsPage> createState() => _LocalReportsPageState();
}

class _LocalReportsPageState extends State<LocalReportsPage> {
  late final LocalReportController _controller =
      widget.controller ?? buildLocalReportController();

  @override
  void initState() {
    super.initState();
    auditAgentProvider.registerReportViewed();
    _controller.addListener(_onChanged);
    _controller.generate(const ReportFilter(title: 'Resumo local'));
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

  Future<void> _refresh() async {
    auditAgentProvider.registerReportGenerated();
    await _controller.generate(const ReportFilter(title: 'Resumo local'));
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Relatorios Locais'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: state.loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? _ErrorState(message: state.error!, onRetry: _refresh)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const Text(
                  'Relatorio offline',
                  style: TextStyle(
                    color: AppColors.navyDeep,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Preparado para exportacao futura em PDF, sem expor dados sensiveis.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final warning in state.report?.warnings ?? const [])
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber),
                      title: Text(warning),
                    ),
                  ),
                for (final section in state.report?.sections ?? const [])
                  ReportSummaryCard(section: section),
              ],
            ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/connectivity/models/connectivity_status.dart';
import '../../../core/sync/models/sync_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/local_indicators.dart';
import '../providers/local_indicators_providers.dart';
import '../widgets/indicator_card.dart';

class LocalIndicatorsPage extends StatefulWidget {
  final LocalIndicatorsController? controller;

  const LocalIndicatorsPage({super.key, this.controller});

  @override
  State<LocalIndicatorsPage> createState() => _LocalIndicatorsPageState();
}

class _LocalIndicatorsPageState extends State<LocalIndicatorsPage> {
  late final LocalIndicatorsController _controller =
      widget.controller ?? buildLocalIndicatorsController();

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

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Indicadores Locais'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: state.status == LocalIndicatorsLoadStatus.loading
                ? null
                : _controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch (state.status) {
        LocalIndicatorsLoadStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        LocalIndicatorsLoadStatus.error => _ErrorState(
          message: state.error ?? 'Nao foi possivel carregar indicadores.',
          onRetry: _controller.load,
        ),
        LocalIndicatorsLoadStatus.empty ||
        LocalIndicatorsLoadStatus.loaded => _IndicatorsContent(
          indicators:
              state.indicators ??
              LocalIndicators.empty().copyWith(
                loadStatus: LocalIndicatorsLoadStatus.loaded,
              ),
          empty: state.status == LocalIndicatorsLoadStatus.empty,
        ),
      },
    );
  }
}

class _IndicatorsContent extends StatelessWidget {
  final LocalIndicators indicators;
  final bool empty;

  const _IndicatorsContent({required this.indicators, required this.empty});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.navyDeep,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumo offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                empty
                    ? 'Sem dados operacionais locais para consolidar.'
                    : 'Dados consolidados diretamente do banco local.',
                style: const TextStyle(color: Color(0xFFD9F0E4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IndicatorCard(
          icon: Icons.route,
          title: 'Viagens',
          value: '${indicators.totalViagens}',
          subtitle:
              '${indicators.viagensPendentes} pendentes | ${indicators.viagensEmAndamento} em andamento | ${indicators.viagensConcluidas} concluidas',
        ),
        IndicatorCard(
          icon: Icons.groups,
          title: 'Passageiros',
          value: '${indicators.passageirosTransportados}',
          subtitle: 'Passageiros transportados registrados localmente.',
          color: Colors.green.shade700,
        ),
        IndicatorCard(
          icon: Icons.report_problem,
          title: 'Ocorrencias',
          value: '${indicators.ocorrenciasRegistradas}',
          subtitle: 'Incidentes e registros operacionais locais.',
          color: Colors.orange.shade800,
        ),
        IndicatorCard(
          icon: Icons.fact_check,
          title: 'Checklists',
          value: '${indicators.checklistsConcluidos}',
          subtitle: 'Checklists concluidos no aparelho.',
          color: Colors.indigo.shade700,
        ),
        IndicatorCard(
          icon: Icons.sync,
          title: 'Sincronizacao',
          value: '${indicators.itensPendentesSincronizacao}',
          subtitle:
              'Pendentes | ${indicators.statusSincronizacao.label} | ultima: ${_formatDate(indicators.ultimaSincronizacao)}',
          color: Colors.blueGrey.shade700,
        ),
        IndicatorCard(
          icon: Icons.network_check,
          title: 'Conexao',
          value: indicators.statusConexao.label,
          subtitle: 'Status informado pelo ConnectivityAgent.',
          color: indicators.statusConexao.canSync
              ? Colors.green.shade800
              : Colors.red.shade700,
        ),
        IndicatorCard(
          icon: Icons.health_and_safety,
          title: 'Saude do app',
          value: indicators.errosRecentes.isEmpty
              ? 'Sem erros recentes'
              : '${indicators.errosRecentes.length} erro(s)',
          subtitle: indicators.errosRecentes.isEmpty
              ? 'Fila local e indicadores carregados sem falhas registradas.'
              : indicators.errosRecentes.take(2).join(' | '),
          color: indicators.errosRecentes.isEmpty
              ? Colors.green.shade800
              : Colors.red.shade700,
        ),
      ],
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'nao disponivel';
    String two(int input) => input.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textStrong),
            ),
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

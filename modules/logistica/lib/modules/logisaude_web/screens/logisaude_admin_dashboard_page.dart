import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../transportes/models/viagem_status.dart';
import '../controllers/logisaude_dashboard_controller.dart';
import '../models/logisaude_dashboard_data.dart';
import '../widgets/alert_card.dart';
import '../widgets/command_card.dart';
import '../widgets/dashboard_section_card.dart';
import '../widgets/executive_metric_card.dart';
import '../widgets/recent_trips_card.dart';
import '../widgets/sync_status_panel.dart';
import '../widgets/tracking_map_panel.dart';
import '../widgets/web_shell.dart';

class LogisaudeAdminDashboardPage extends StatefulWidget {
  const LogisaudeAdminDashboardPage({super.key});

  @override
  State<LogisaudeAdminDashboardPage> createState() =>
      _LogisaudeAdminDashboardPageState();
}

class _LogisaudeAdminDashboardPageState
    extends State<LogisaudeAdminDashboardPage> {
  late final LogisaudeDashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = LogisaudeDashboardController()..carregar();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final data = controller.data;
        return WebShell(
          atualizadoEm: data?.atualizadoEm,
          child: controller.carregando && data == null
              ? const Center(child: CircularProgressIndicator())
              : controller.erro != null && data == null
              ? _ErrorState(
                  error: controller.erro!,
                  onRetry: controller.carregar,
                )
              : _DashboardBody(
                  data: data!,
                  busy: controller.carregando,
                  onRefresh: controller.carregar,
                  onSync: controller.solicitarSincronizacao,
                  onRetryQueue: controller.reprocessarPendencias,
                ),
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final LogisaudeDashboardData data;
  final bool busy;
  final VoidCallback onRefresh;
  final VoidCallback onSync;
  final VoidCallback onRetryQueue;

  const _DashboardBody({
    required this.data,
    required this.busy,
    required this.onRefresh,
    required this.onSync,
    required this.onRetryQueue,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1050;
        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 28,
                compact ? 14 : 22,
                compact ? 14 : 28,
                18,
              ),
              child: Column(
                children: [
                  _MetricsGrid(data: data, compact: compact),
                  const SizedBox(height: 18),
                  if (compact)
                    Column(
                      children: [
                        TrackingMapPanel(
                          pontos: data.rastreamentos,
                          viagens: data.viagens,
                          onRefresh: onRefresh,
                        ),
                        const SizedBox(height: 16),
                        _RightPanel(
                          data: data,
                          onRefresh: onRefresh,
                          onSync: onSync,
                          onRetryQueue: onRetryQueue,
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: TrackingMapPanel(
                            pontos: data.rastreamentos,
                            viagens: data.viagens,
                            onRefresh: onRefresh,
                          ),
                        ),
                        const SizedBox(width: 18),
                        SizedBox(
                          width: 338,
                          child: _RightPanel(
                            data: data,
                            onRefresh: onRefresh,
                            onSync: onSync,
                            onRetryQueue: onRetryQueue,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  _LowerSections(data: data, compact: compact),
                  const SizedBox(height: 18),
                  _OperationalFooter(data: data, compact: compact),
                ],
              ),
            ),
            if (busy)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        );
      },
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final LogisaudeDashboardData data;
  final bool compact;

  const _MetricsGrid({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ExecutiveMetricCard(
        icon: Icons.event_available_rounded,
        title: 'Viagens do Dia',
        value: '${data.viagensDoDia}',
        subtitle: 'agenda local',
        trend: '${data.viagens.length} viagens totais',
        color: AppColors.primary,
      ),
      ExecutiveMetricCard(
        icon: Icons.play_circle_rounded,
        title: 'Em Andamento',
        value: '${data.viagensEmAndamento}',
        subtitle: 'rotas ativas',
        trend: 'monitoramento ativo',
        color: const Color(0xFF168039),
      ),
      ExecutiveMetricCard(
        icon: Icons.warning_rounded,
        title: 'Pendências',
        value: '${data.pendencias}',
        subtitle: 'fila local',
        trend: '${data.syncPorStatus['failed'] ?? 0} falhas',
        positive: false,
        color: const Color(0xFFFBC02D),
      ),
      ExecutiveMetricCard(
        icon: Icons.person_pin_circle_rounded,
        title: 'Motoristas Ativos',
        value: '${data.motoristasAtivos}',
        subtitle: 'cadastro local',
        trend: '${data.motoristas.length} cadastrados',
        color: AppColors.primary,
      ),
      ExecutiveMetricCard(
        icon: Icons.directions_car_rounded,
        title: 'Veículos Ativos',
        value: '${data.veiculosAtivos}',
        subtitle: 'frota local',
        trend: '${data.veiculos.length} cadastrados',
        color: const Color(0xFF687785),
      ),
      ExecutiveMetricCard(
        icon: Icons.report_problem_rounded,
        title: 'Alertas Críticos',
        value: '${data.alertasCriticos}',
        subtitle: 'operação',
        trend: data.alertasCriticos == 0 ? 'sem críticos' : 'atenção requerida',
        positive: data.alertasCriticos == 0,
        color: const Color(0xFFE53935),
      ),
      ExecutiveMetricCard(
        icon: Icons.cloud_sync_rounded,
        title: 'Sync Pendente',
        value: '${data.pendencias}',
        subtitle: 'offline-first',
        trend: 'fila sync_queue',
        positive: data.pendencias == 0,
        color: const Color(0xFF168039),
      ),
      ExecutiveMetricCard(
        icon: Icons.wifi_rounded,
        title: 'Status do Sistema',
        value: data.servidorOnline ? 'Online' : 'Offline',
        subtitle: 'servidor/API',
        trend: data.servidorOnline ? 'operacional' : 'sem conexão',
        positive: data.servidorOnline,
        color: data.servidorOnline
            ? const Color(0xFF168039)
            : const Color(0xFF687785),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 1 : 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 108,
      ),
      itemBuilder: (context, index) => metrics[index],
    );
  }
}

class _RightPanel extends StatelessWidget {
  final LogisaudeDashboardData data;
  final VoidCallback onRefresh;
  final VoidCallback onSync;
  final VoidCallback onRetryQueue;

  const _RightPanel({
    required this.data,
    required this.onRefresh,
    required this.onSync,
    required this.onRetryQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashboardSectionCard(
          title: 'Alertas Críticos',
          trailing: const Text(
            'Ver todos',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: Column(
            children: [
              AlertCard(
                icon: Icons.signal_wifi_off_rounded,
                title: 'Motorista offline',
                subtitle: data.servidorOnline
                    ? 'Sem ocorrências recentes'
                    : 'Servidor/API indisponível',
                count: data.offlineOperacional,
                color: const Color(0xFFE53935),
              ),
              AlertCard(
                icon: Icons.timer_off_rounded,
                title: 'Viagem atrasada',
                subtitle: 'Status local de atraso',
                count: data.viagensAtrasadas,
                color: const Color(0xFFFB8C00),
              ),
              AlertCard(
                icon: Icons.assignment_late_rounded,
                title: 'Solicitação pendente',
                subtitle: 'Itens aguardando sync',
                count: data.pendencias,
                color: const Color(0xFFFBC02D),
              ),
              AlertCard(
                icon: Icons.cloud_off_rounded,
                title: 'Falha de sincronização',
                subtitle: 'Registros em failed',
                count: data.syncPorStatus['failed'] ?? 0,
                color: const Color(0xFFE53935),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        DashboardSectionCard(
          title: 'Comandos Operacionais',
          child: Column(
            children: [
              CommandCard(
                icon: Icons.refresh_rounded,
                label: 'Atualizar rastreamento',
                onPressed: onRefresh,
              ),
              CommandCard(
                icon: Icons.cloud_sync_rounded,
                label: 'Solicitar sincronização',
                onPressed: onSync,
              ),
              CommandCard(
                icon: Icons.replay_rounded,
                label: 'Reprocessar pendências',
                onPressed: onRetryQueue,
              ),
              const CommandCard(
                icon: Icons.send_rounded,
                label: 'Enviar comando ao motorista',
              ),
              const CommandCard(
                icon: Icons.lock_rounded,
                label: 'Bloquear viagem',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        RecentTripsCard(viagens: data.viagens),
      ],
    );
  }
}

class _LowerSections extends StatelessWidget {
  final LogisaudeDashboardData data;
  final bool compact;

  const _LowerSections({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _TripsByStatus(data: data),
      _TripsByUnit(data: data),
      _TripHistory(data: data),
      SyncStatusPanel(
        porStatus: data.syncPorStatus,
        recentes: data.syncRecentes,
      ),
    ];

    if (compact) {
      return Column(
        children: sections
            .map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: section,
              ),
            )
            .toList(),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: 1.18,
      children: sections,
    );
  }
}

class _TripsByStatus extends StatelessWidget {
  final LogisaudeDashboardData data;

  const _TripsByStatus({required this.data});

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: 'Viagens por Status',
      child: data.viagensPorStatus.isEmpty
          ? const Text(
              'Sem viagens cadastradas.',
              style: TextStyle(color: AppColors.textMuted),
            )
          : Column(
              children: data.viagensPorStatus.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: entry.value / data.viagens.length,
                              color: _statusColor(entry.key),
                              backgroundColor: const Color(0xFFE8EFEA),
                              minHeight: 12,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Color _statusColor(String status) {
    if (status == ViagemStatus.concluida) return const Color(0xFF168039);
    if (status == ViagemStatus.emAndamento) return AppColors.primary;
    if (status == ViagemStatus.cancelada) return const Color(0xFFE53935);
    return const Color(0xFFFB8C00);
  }
}

class _TripsByUnit extends StatelessWidget {
  final LogisaudeDashboardData data;

  const _TripsByUnit({required this.data});

  @override
  Widget build(BuildContext context) {
    final unidades = <String, int>{};
    for (final viagem in data.viagens) {
      final key = viagem.origem.isEmpty
          ? 'Origem não informada'
          : viagem.origem;
      unidades[key] = (unidades[key] ?? 0) + 1;
    }

    return DashboardSectionCard(
      title: 'Viagens por Unidade',
      child: unidades.isEmpty
          ? const Text(
              'Sem dados de unidade.',
              style: TextStyle(color: AppColors.textMuted),
            )
          : Column(
              children: unidades.entries.take(6).map((entry) {
                final max = unidades.values.reduce((a, b) => a > b ? a : b);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: entry.value / max,
                          color: AppColors.primary,
                          backgroundColor: const Color(0xFFE8EFEA),
                          minHeight: 11,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _TripHistory extends StatelessWidget {
  final LogisaudeDashboardData data;

  const _TripHistory({required this.data});

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: 'Histórico de Viagens',
      child: SizedBox(
        height: 150,
        child: CustomPaint(
          painter: _HistoryPainter(total: data.viagens.length),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _HistoryPainter extends CustomPainter {
  final int total;

  const _HistoryPainter({required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = const Color(0xFFE8EFEA)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = 16 + i * ((size.height - 36) / 3);
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), axis);
    }

    // Placeholder visual derivado do total real atual; substituir por série
    // histórica real quando o repositório expuser agregação temporal.
    final values = [0.45, 0.55, 0.62, 0.72, 0.86, total > 0 ? 1.0 : 0.35];
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = 12 + i * ((size.width - 24) / (values.length - 1));
      final y = size.height - 22 - values[i] * (size.height - 44);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = AppColors.primary);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter oldDelegate) {
    return oldDelegate.total != total;
  }
}

class _OperationalFooter extends StatelessWidget {
  final LogisaudeDashboardData data;
  final bool compact;

  const _OperationalFooter({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.cloud_sync_rounded,
        'Sincronização',
        'Última: ${_hora(data.atualizadoEm)}',
      ),
      (
        Icons.wifi_rounded,
        'Conexão',
        data.servidorOnline ? 'Online' : 'Offline',
      ),
      (
        Icons.event_note_rounded,
        'Eventos (24h)',
        '${data.syncRecentes.length}',
      ),
      (Icons.people_rounded, 'Usuários Online', '1'),
      (
        Icons.verified_rounded,
        'Status',
        data.servidorOnline ? 'Operacional' : 'Atenção',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4ECE7)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 30,
        runSpacing: 16,
        children: items
            .map(
              (item) => SizedBox(
                width: compact ? double.infinity : 205,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(item.$1, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            item.$3,
                            style: const TextStyle(
                              color: AppColors.textStrong,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _hora(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42, color: Color(0xFFE53935)),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

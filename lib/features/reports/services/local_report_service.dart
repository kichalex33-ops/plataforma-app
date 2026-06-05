import '../../../core/agents/agents.dart';
import '../../indicators/services/local_indicators_service.dart';
import '../models/local_report.dart';
import '../models/report_filter.dart';

class LocalReportService {
  final ReportAgent reportAgent;
  final ValidationAgent validationAgent;
  final AppHealthAgent appHealthAgent;
  final LocalIndicatorsService indicatorsService;

  LocalReportService({
    required this.reportAgent,
    required this.validationAgent,
    required this.appHealthAgent,
    required this.indicatorsService,
  });

  Future<LocalReport> generate(ReportFilter filter) {
    validationAgent.ensureReportFilter(filter.start, filter.end);
    return reportAgent.consolidate(
      reportName: 'relatorios_locais',
      builder: () => _build(filter),
    );
  }

  Future<LocalReport> _build(ReportFilter filter) async {
    final indicators = await indicatorsService.refresh();
    final health = await appHealthAgent.snapshot();

    return LocalReport(
      title: filter.title,
      generatedAt: DateTime.now(),
      warnings: [
        if (indicators.errosRecentes.isNotEmpty)
          'Existem erros locais recentes.',
        if (health.pendingItems > 0) 'Existem pendencias de sincronizacao.',
      ],
      sections: [
        LocalReportSection(
          title: 'Viagens',
          metrics: [
            LocalReportMetric(
              key: 'total_viagens',
              label: 'Total de viagens',
              value: indicators.totalViagens,
              description: 'Viagens salvas localmente.',
            ),
            LocalReportMetric(
              key: 'viagens_pendentes',
              label: 'Pendentes',
              value: indicators.viagensPendentes,
              description: 'Viagens aguardando andamento ou revisao.',
            ),
            LocalReportMetric(
              key: 'viagens_em_andamento',
              label: 'Em andamento',
              value: indicators.viagensEmAndamento,
              description: 'Viagens em fluxo operacional.',
            ),
            LocalReportMetric(
              key: 'viagens_concluidas',
              label: 'Concluidas',
              value: indicators.viagensConcluidas,
              description: 'Viagens finalizadas no app.',
            ),
          ],
        ),
        LocalReportSection(
          title: 'Passageiros',
          metrics: [
            LocalReportMetric(
              key: 'passageiros_transportados',
              label: 'Transportados',
              value: indicators.passageirosTransportados,
              description: 'Passageiros registrados como transportados.',
            ),
          ],
        ),
        LocalReportSection(
          title: 'Ocorrencias',
          metrics: [
            LocalReportMetric(
              key: 'ocorrencias',
              label: 'Ocorrencias',
              value: indicators.ocorrenciasRegistradas,
              description: 'Ocorrencias registradas localmente.',
            ),
          ],
        ),
        LocalReportSection(
          title: 'Checklists',
          metrics: [
            LocalReportMetric(
              key: 'checklists_concluidos',
              label: 'Concluidos',
              value: indicators.checklistsConcluidos,
              description: 'Checklists concluidos no aparelho.',
            ),
          ],
        ),
        LocalReportSection(
          title: 'Sincronizacao',
          metrics: [
            LocalReportMetric(
              key: 'pendencias_sync',
              label: 'Pendencias',
              value: indicators.itensPendentesSincronizacao,
              description: 'Itens aguardando envio ou revisao de sync.',
            ),
          ],
        ),
        LocalReportSection(
          title: 'Saude local',
          metrics: [
            LocalReportMetric(
              key: 'erros_recentes',
              label: 'Erros recentes',
              value: indicators.errosRecentes.length,
              description: 'Erros locais usados para diagnostico.',
            ),
            LocalReportMetric(
              key: 'eventos_auditoria',
              label: 'Eventos de auditoria',
              value: health.auditEvents,
              description: 'Eventos registrados nesta sessao do app.',
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../auth/motorista_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../modules/transportes/models/viagem_model.dart';
import '../../modules/transportes/models/viagem_status.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/sync_status_card.dart';
import '../../widgets/sync_status_badge.dart';
import '../preparacao/preparacao_viagem_page.dart';
import '../sync/driver_sync_panel.dart';
import '../viagem_atual/viagem_detalhe_page.dart';
import 'minhas_viagens_controller.dart';
import 'minhas_viagens_repository.dart';

class MinhasViagensPage extends StatefulWidget {
  final bool embed;
  final MotoristaModel? motorista;
  final String? motoristaId;

  const MinhasViagensPage({
    super.key,
    this.embed = false,
    this.motorista,
    this.motoristaId,
  });

  @override
  State<MinhasViagensPage> createState() => _MinhasViagensPageState();
}

class _MinhasViagensPageState extends State<MinhasViagensPage> {
  late final MinhasViagensController controller;

  String get motoristaId =>
      widget.motorista?.id ?? widget.motoristaId ?? 'motorista-local';

  MotoristaModel get motoristaAtual =>
      widget.motorista ??
      MotoristaModel(
        id: motoristaId,
        nome: 'Motorista local',
        municipio: 'Município local',
      );

  @override
  void initState() {
    super.initState();
    controller = MinhasViagensController()..carregar(motoristaId);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _formatarData(String valor) {
    final data = DateTime.tryParse(valor);
    if (data == null) return valor;

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  void _abrirDetalhe(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViagemDetalhePage(
          viagem: controller.viagens[index],
          motorista: motoristaAtual,
        ),
      ),
    );
  }

  Future<void> _iniciarPreparacao(int index) async {
    final atualizou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PreparacaoViagemPage(
          viagem: controller.viagens[index],
          motorista: motoristaAtual,
        ),
      ),
    );

    if (atualizou == true) {
      await controller.carregar(motoristaId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embed ? null : AppBar(title: const Text('Minhas viagens')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SyncStatusCard(
                  online: controller.servidorOnline,
                  title: 'Status do servidor',
                  description: controller.servidorOnline
                      ? 'Viagens podem ser atualizadas pelo backend.'
                      : 'Mostrando dados locais disponíveis offline.',
                  child: const DriverSyncPanel(),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: controller.carregando
                    ? const Center(child: CircularProgressIndicator())
                    : controller.erro != null
                    ? Center(
                        child: Text(
                          controller.erro!,
                          style: const TextStyle(color: AppColors.atrasado),
                        ),
                      )
                    : controller.viagens.isEmpty
                    ? const EmptyStateCard(
                        icon: Icons.route,
                        title: 'Nenhuma viagem atribuída',
                        message:
                            'As próximas viagens aparecem aqui quando o painel atribuir rotas ao motorista.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => controller.carregar(motoristaId),
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: [
                            SectionHeader(
                              title: 'Viagens atribuídas',
                              subtitle:
                                  '${controller.viagens.length} viagem(ns) para este motorista.',
                            ),
                            ...List.generate(controller.viagens.length, (
                              index,
                            ) {
                              final viagem = controller.viagens[index];
                              final resumo =
                                  controller.resumos[viagem.sync.id] ??
                                  const ViagemAtribuidaResumo();
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _ViagemCard(
                                  origem: viagem.origem,
                                  destino: viagem.destino,
                                  horario: _formatarData(viagem.dataHoraSaida),
                                  status: viagem.estadoOperacional,
                                  finalidade: viagem.finalidade,
                                  syncStatus: viagem.sync.syncStatus,
                                  prioridade: viagem.prioridade,
                                  pacientes: resumo.pacientes,
                                  acompanhantes: resumo.acompanhantes,
                                  possuiAcessibilidade:
                                      resumo.possuiAcessibilidade,
                                  tipoVisual: _tipoVisual(viagem),
                                  onTap: () => _abrirDetalhe(index),
                                  onPreparacao: () => _iniciarPreparacao(index),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _tipoVisual(ViagemModel viagem) {
    if (viagem.isTransferencia) return 'Transferência';
    if (viagem.isRetorno) return 'Retorno';
    if (viagem.isPrioritaria) return 'Prioritária';
    return 'Comum';
  }
}

class _ViagemCard extends StatelessWidget {
  final String origem;
  final String destino;
  final String horario;
  final String status;
  final String? finalidade;
  final String syncStatus;
  final String prioridade;
  final int pacientes;
  final int acompanhantes;
  final bool possuiAcessibilidade;
  final String tipoVisual;
  final VoidCallback onTap;
  final VoidCallback onPreparacao;

  const _ViagemCard({
    required this.origem,
    required this.destino,
    required this.horario,
    required this.status,
    required this.finalidade,
    required this.syncStatus,
    required this.prioridade,
    required this.pacientes,
    required this.acompanhantes,
    required this.possuiAcessibilidade,
    required this.tipoVisual,
    required this.onTap,
    required this.onPreparacao,
  });

  @override
  Widget build(BuildContext context) {
    final destaque = _corTipo(tipoVisual);
    return Card(
      color: possuiAcessibilidade ? const Color(0xFFFFF8E1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: destaque.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                    ),
                    child: Icon(Icons.route, color: destaque),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$origem -> $destino',
                          style: const TextStyle(
                            color: AppColors.textStrong,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          horario,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatusBadge(
                    label: ViagemStatus.label(status),
                    status: status,
                  ),
                  SyncStatusBadge(status: syncStatus),
                  Chip(label: Text(tipoVisual)),
                  Chip(label: Text('Prioridade: $prioridade')),
                  Chip(label: Text('$pacientes paciente(s)')),
                  Chip(label: Text('$acompanhantes acompanhante(s)')),
                  if (possuiAcessibilidade)
                    const Chip(
                      avatar: Icon(Icons.accessible, size: 18),
                      label: Text('Acessibilidade'),
                    ),
                  if (finalidade?.isNotEmpty == true)
                    Chip(label: Text(finalidade!)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onPreparacao,
                  icon: const Icon(Icons.fact_check),
                  label: const Text('Iniciar Preparação'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _corTipo(String tipo) {
    return switch (tipo) {
      'Prioritária' => const Color(0xFFC62828),
      'Transferência' => const Color(0xFF1565C0),
      'Retorno' => const Color(0xFF6A1B9A),
      _ => AppColors.primary,
    };
  }
}

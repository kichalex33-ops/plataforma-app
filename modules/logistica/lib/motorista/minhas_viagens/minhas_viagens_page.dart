import 'package:flutter/material.dart';

import '../../auth/motorista_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../modules/transportes/models/viagem_status.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/sync_status_card.dart';
import '../../widgets/sync_status_badge.dart';
import '../sync/driver_sync_panel.dart';
import '../viagem_atual/viagem_detalhe_page.dart';
import 'minhas_viagens_controller.dart';

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
        municipio: 'Municipio local',
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
                      : 'Mostrando dados locais disponiveis offline.',
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
                        title: 'Nenhuma viagem atribuida',
                        message:
                            'As proximas viagens aparecem aqui quando o painel web atribuir rotas ao motorista.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => controller.carregar(motoristaId),
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: [
                            SectionHeader(
                              title: 'Viagens atribuidas',
                              subtitle:
                                  '${controller.viagens.length} viagem(ns) para este motorista.',
                            ),
                            ...List.generate(controller.viagens.length, (
                              index,
                            ) {
                              final viagem = controller.viagens[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _ViagemCard(
                                  origem: viagem.origem,
                                  destino: viagem.destino,
                                  horario: _formatarData(viagem.dataHoraSaida),
                                  status: viagem.status,
                                  finalidade: viagem.finalidade,
                                  syncStatus: viagem.sync.syncStatus,
                                  onTap: () => _abrirDetalhe(index),
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
}

class _ViagemCard extends StatelessWidget {
  final String origem;
  final String destino;
  final String horario;
  final String status;
  final String? finalidade;
  final String syncStatus;
  final VoidCallback onTap;

  const _ViagemCard({
    required this.origem,
    required this.destino,
    required this.horario,
    required this.status,
    required this.finalidade,
    required this.syncStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                    ),
                    child: const Icon(Icons.route, color: AppColors.primary),
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
                  if (finalidade?.isNotEmpty == true)
                    Chip(label: Text(finalidade!)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

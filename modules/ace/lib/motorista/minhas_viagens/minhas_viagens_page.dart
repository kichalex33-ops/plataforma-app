import 'package:flutter/material.dart';

import '../../auth/motorista_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../modules/transportes/models/viagem_status.dart';
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      controller.servidorOnline
                          ? 'Servidor: online'
                          : 'Servidor: offline',
                      style: TextStyle(
                        color: controller.servidorOnline
                            ? Colors.green.shade800
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const DriverSyncPanel(),
                  ],
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
                    ? const Center(
                        child: Text(
                          'Nenhuma viagem atribuida',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => controller.carregar(motoristaId),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: controller.viagens.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final viagem = controller.viagens[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.route,
                                  color: AppColors.primary,
                                ),
                                title: Text(
                                  '${viagem.origem} -> ${viagem.destino}',
                                ),
                                subtitle: Text(
                                  [
                                    ViagemStatus.label(viagem.status),
                                    _formatarData(viagem.dataHoraSaida),
                                    if (viagem.finalidade?.isNotEmpty == true)
                                      viagem.finalidade,
                                  ].whereType<String>().join(' | '),
                                ),
                                onTap: () => _abrirDetalhe(index),
                              ),
                            );
                          },
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

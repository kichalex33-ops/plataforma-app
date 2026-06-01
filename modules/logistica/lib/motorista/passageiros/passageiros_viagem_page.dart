import 'package:flutter/material.dart';

import '../../auth/motorista_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../modules/transportes/models/passageiro_model.dart';
import '../../modules/transportes/models/viagem_model.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import 'models/passageiro_operacao.dart';
import 'passageiros_controller.dart';

class PassageirosViagemPage extends StatefulWidget {
  final ViagemModel viagem;
  final MotoristaModel motorista;

  const PassageirosViagemPage({
    super.key,
    required this.viagem,
    required this.motorista,
  });

  @override
  State<PassageirosViagemPage> createState() => _PassageirosViagemPageState();
}

class _PassageirosViagemPageState extends State<PassageirosViagemPage> {
  late final PassageirosController controller;

  @override
  void initState() {
    super.initState();
    controller = PassageirosController()..carregar(widget.viagem.sync.id);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _registrarOperacao(
    PassageiroModel passageiro,
    String operacao,
  ) async {
    await controller.registrarOperacao(
      viagem: widget.viagem,
      motorista: widget.motorista,
      passageiro: passageiro,
      operacao: operacao,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento registrado localmente.')),
    );
  }

  Future<void> _registrarObservacao(PassageiroModel passageiro) async {
    final textoController = TextEditingController(
      text: controller.observacoesLocais[passageiro.sync.id] ?? '',
    );

    final observacao = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observacao rapida'),
        content: TextField(
          controller: textoController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Observacao',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textoController.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    textoController.dispose();
    if (observacao == null || observacao.trim().isEmpty) return;

    await controller.registrarObservacao(
      viagem: widget.viagem,
      motorista: widget.motorista,
      passageiro: passageiro,
      observacao: observacao.trim(),
      operacao: PassageiroOperacao.observacaoRegistrada,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento registrado localmente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passageiros da viagem')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.erro != null) {
            return Center(
              child: Text(
                controller.erro!,
                style: const TextStyle(color: AppColors.atrasado),
              ),
            );
          }

          if (controller.passageiros.isEmpty) {
            return const EmptyStateCard(
              icon: Icons.airline_seat_recline_normal,
              title: 'Nenhum passageiro vinculado',
              message:
                  'Os passageiros da viagem aparecerao aqui quando forem enviados pelo painel.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              SectionHeader(
                title: 'Passageiros',
                subtitle:
                    '${controller.passageiros.length} passageiro(s) vinculados a viagem.',
              ),
              ...List.generate(controller.passageiros.length, (index) {
                final passageiro = controller.passageiros[index];
                final operacao = controller.operacoesLocais[passageiro.sync.id];
                final observacaoLocal =
                    controller.observacoesLocais[passageiro.sync.id];

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PassageiroCard(
                    passageiro: passageiro,
                    operacaoLocal: operacao,
                    observacaoLocal: observacaoLocal,
                    onEmbarque: () => _registrarOperacao(
                      passageiro,
                      PassageiroOperacao.embarqueConfirmado,
                    ),
                    onChegada: () => _registrarOperacao(
                      passageiro,
                      PassageiroOperacao.chegadaConfirmada,
                    ),
                    onAusencia: () => _registrarOperacao(
                      passageiro,
                      PassageiroOperacao.passageiroAusente,
                    ),
                    onObservacao: () => _registrarObservacao(passageiro),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _PassageiroCard extends StatelessWidget {
  final PassageiroModel passageiro;
  final String? operacaoLocal;
  final String? observacaoLocal;
  final VoidCallback onEmbarque;
  final VoidCallback onChegada;
  final VoidCallback onAusencia;
  final VoidCallback onObservacao;

  const _PassageiroCard({
    required this.passageiro,
    required this.operacaoLocal,
    required this.observacaoLocal,
    required this.onEmbarque,
    required this.onChegada,
    required this.onAusencia,
    required this.onObservacao,
  });

  @override
  Widget build(BuildContext context) {
    final detalhes = [
      if (passageiro.embarque?.isNotEmpty == true)
        'Origem: ${passageiro.embarque}',
      if (passageiro.desembarque?.isNotEmpty == true)
        'Destino: ${passageiro.desembarque}',
      if (passageiro.necessidadeEspecial?.isNotEmpty == true)
        'Necessidade: ${passageiro.necessidadeEspecial}',
      if (passageiro.observacoes?.isNotEmpty == true)
        'Obs.: ${passageiro.observacoes}',
      if (observacaoLocal?.isNotEmpty == true) 'Obs. local: $observacaoLocal',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: const Icon(
                  Icons.airline_seat_recline_normal,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                passageiro.nome,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(detalhes.join('\n')),
              trailing: StatusBadge(
                label: operacaoLocal ?? passageiro.status,
                status: operacaoLocal ?? passageiro.status,
              ),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: onEmbarque,
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text('Confirmar embarque'),
                ),
                OutlinedButton.icon(
                  onPressed: onChegada,
                  icon: const Icon(Icons.flag),
                  label: const Text('Confirmar chegada'),
                ),
                OutlinedButton.icon(
                  onPressed: onAusencia,
                  icon: const Icon(Icons.person_off),
                  label: const Text('Marcar ausencia'),
                ),
                OutlinedButton.icon(
                  onPressed: onObservacao,
                  icon: const Icon(Icons.note_add),
                  label: const Text('Observacao rapida'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

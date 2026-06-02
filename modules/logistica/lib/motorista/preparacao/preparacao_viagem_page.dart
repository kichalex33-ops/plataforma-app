import 'package:flutter/material.dart';

import '../../auth/motorista_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../modules/transportes/models/passageiro_model.dart';
import '../../modules/transportes/models/viagem_model.dart';
import '../../modules/transportes/models/viagem_status.dart';
import '../../widgets/section_header.dart';
import '../passageiros/passageiros_repository.dart';
import 'models/viagem_preparacao_model.dart';
import 'viagem_preparacao_repository.dart';
import 'viagem_preparacao_service.dart';

class PreparacaoViagemPage extends StatefulWidget {
  final ViagemModel viagem;
  final MotoristaModel motorista;

  const PreparacaoViagemPage({
    super.key,
    required this.viagem,
    required this.motorista,
  });

  @override
  State<PreparacaoViagemPage> createState() => _PreparacaoViagemPageState();
}

class _PreparacaoViagemPageState extends State<PreparacaoViagemPage> {
  late final ViagemPreparacaoService service;
  late final PassageirosRepository passageirosRepository;
  late Future<void> _carregamento;
  final TextEditingController _kmController = TextEditingController();
  final Map<String, bool> _checklist = {
    'Pneus calibrados': false,
    'Freios conferidos': false,
    'Luzes e setas funcionando': false,
    'Documentos do veiculo': false,
    'Higienizacao e maca/cadeira conferidas': false,
  };

  ViagemPreparacaoModel? preparacao;
  List<PassageiroModel> passageiros = const [];
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    service = ViagemPreparacaoService(store: ViagemPreparacaoRepository());
    passageirosRepository = PassageirosRepository();
    _carregamento = _iniciar();
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    passageiros = await passageirosRepository.listarPorViagem(
      widget.viagem.sync.id,
    );
    preparacao = await service.iniciarPreparacao(
      viagem: widget.viagem,
      motorista: widget.motorista,
    );
  }

  int get totalAcompanhantes =>
      passageiros.where((item) => item.acompanhante).length;

  bool get possuiAcessibilidade =>
      passageiros.any((item) => item.possuiAcessibilidade);

  Future<void> _confirmarSaida() async {
    final km = double.tryParse(_kmController.text.replaceAll(',', '.'));
    setState(() => salvando = true);

    try {
      await service.confirmarSaida(
        viagem: widget.viagem,
        motorista: widget.motorista,
        preparacao: preparacao!,
        kmInicial: km,
        checklist: _checklist,
      );
      await service.iniciarTransitoIda(
        viagem: widget.viagem,
        motorista: widget.motorista,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saida confirmada e evento salvo offline.'),
        ),
      );
      Navigator.pop(context, true);
    } on ViagemPreparacaoException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preparação da viagem')),
      body: FutureBuilder<void>(
        future: _carregamento,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _ResumoViagemCard(
                viagem: widget.viagem,
                totalPacientes: passageiros.length,
                totalAcompanhantes: totalAcompanhantes,
                possuiAcessibilidade: possuiAcessibilidade,
              ),
              const SizedBox(height: AppSpacing.md),
              const SectionHeader(
                title: 'Dados da saida',
                subtitle:
                    'Preencha o KM inicial e conclua o checklist pre-uso.',
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _InfoLine('Motorista', widget.motorista.nome),
                      _InfoLine(
                        'Veiculo',
                        widget.viagem.veiculoId ?? 'A definir',
                      ),
                      _InfoLine(
                        'Horario automatico',
                        DateTime.now().toString(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _kmController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'KM inicial',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.speed),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const SectionHeader(
                title: 'Checklist pre-uso',
                subtitle: 'Todos os itens sao obrigatorios para confirmar.',
              ),
              Card(
                child: Column(
                  children: _checklist.keys.map((item) {
                    return CheckboxListTile(
                      value: _checklist[item],
                      title: Text(item),
                      onChanged: (value) {
                        setState(() => _checklist[item] = value ?? false);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const SectionHeader(
                title: 'Pacientes e acompanhantes',
                subtitle: 'Conferencia operacional antes da saida.',
              ),
              if (passageiros.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Nenhum paciente vinculado a esta viagem ainda.',
                    ),
                  ),
                )
              else
                ...passageiros.map((item) => _PacientePreparacaoCard(item)),
              if (widget.viagem.observacoesCentral?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.md),
                _AvisoCentralCard(texto: widget.viagem.observacoesCentral!),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: salvando ? null : _confirmarSaida,
                icon: salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: const Text('Confirmar Saida'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResumoViagemCard extends StatelessWidget {
  final ViagemModel viagem;
  final int totalPacientes;
  final int totalAcompanhantes;
  final bool possuiAcessibilidade;

  const _ResumoViagemCard({
    required this.viagem,
    required this.totalPacientes,
    required this.totalAcompanhantes,
    required this.possuiAcessibilidade,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: possuiAcessibilidade ? const Color(0xFFFFF8E1) : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${viagem.origem} -> ${viagem.destinoExibicao}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Chip(
                  label: Text(
                    'Status: ${ViagemStatus.label(viagem.estadoOperacional)}',
                  ),
                ),
                Chip(label: Text('Prioridade: ${viagem.prioridade}')),
                Chip(label: Text('$totalPacientes paciente(s)')),
                Chip(label: Text('$totalAcompanhantes acompanhante(s)')),
                if (possuiAcessibilidade)
                  const Chip(
                    avatar: Icon(Icons.accessible, size: 18),
                    label: Text('Acessibilidade'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PacientePreparacaoCard extends StatelessWidget {
  final PassageiroModel passageiro;

  const _PacientePreparacaoCard(this.passageiro);

  @override
  Widget build(BuildContext context) {
    final alertas = [
      if (passageiro.cadeirante) 'Cadeirante',
      if (passageiro.mobilidadeReduzida) 'Mobilidade reduzida',
      if (passageiro.acompanhanteObrigatorio) 'Acompanhante obrigatorio',
      if (passageiro.acompanhante) 'Acompanhante',
      if (passageiro.acessibilidade?.isNotEmpty == true)
        passageiro.acessibilidade!,
    ];

    return Card(
      child: ListTile(
        leading: Icon(
          passageiro.possuiAcessibilidade ? Icons.accessible : Icons.person,
          color: passageiro.possuiAcessibilidade
              ? Colors.orange.shade800
              : AppColors.primary,
        ),
        title: Text(passageiro.nome),
        subtitle: Text(
          [
            if (passageiro.enderecoEmbarque?.isNotEmpty == true)
              'Embarque: ${passageiro.enderecoEmbarque}',
            if (passageiro.telefone?.isNotEmpty == true)
              'Telefone: ${passageiro.telefone}',
            if (alertas.isNotEmpty) 'Alertas: ${alertas.join(', ')}',
            if (passageiro.observacoesEmbarque?.isNotEmpty == true)
              'Obs.: ${passageiro.observacoesEmbarque}',
          ].join('\n'),
        ),
      ),
    );
  }
}

class _AvisoCentralCard extends StatelessWidget {
  final String texto;

  const _AvisoCentralCard({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryLight,
      child: ListTile(
        leading: const Icon(Icons.campaign, color: AppColors.primary),
        title: const Text('Observacoes da central'),
        subtitle: Text(texto),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

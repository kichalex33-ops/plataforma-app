import 'package:flutter/material.dart';

import '../../core/logistica/logistica_calculator.dart';
import '../../core/logistica/logistica_enums.dart';
import '../../core/logistica/logistica_validators.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/section_header.dart';
import 'logistica_operacional_repository.dart';

class LogisticaViagensAtribuidasPage extends StatefulWidget {
  const LogisticaViagensAtribuidasPage({super.key});

  @override
  State<LogisticaViagensAtribuidasPage> createState() =>
      _LogisticaViagensAtribuidasPageState();
}

class _LogisticaViagensAtribuidasPageState
    extends State<LogisticaViagensAtribuidasPage> {
  final repository = LogisticaOperacionalRepository();
  late Future<List<LogisticaTripSnapshot>> future = repository
      .listarViagensDoDia();

  Future<void> _reload() async {
    setState(() => future = repository.listarViagensDoDia());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viagens atribuídas')),
      body: FutureBuilder<List<LogisticaTripSnapshot>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final viagens = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const SectionHeader(
                  title: 'Viagens do dia',
                  subtitle:
                      'Viagens atribuídas pela plataforma ou seed de homologação.',
                ),
                if (viagens.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nenhuma viagem atribuída',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'As viagens aparecerão aqui quando forem enviadas pelo painel.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ...viagens.map(
                  (item) => _ViagemAtribuidaCard(
                    snapshot: item,
                    onTap: () async {
                      await repository.iniciarPreparacao(item.viagemId);
                      if (!context.mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LogisticaPreparacaoPage(
                            viagemId: item.viagemId,
                            repository: repository,
                          ),
                        ),
                      );
                      await _reload();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ViagemAtribuidaCard extends StatelessWidget {
  final LogisticaTripSnapshot snapshot;
  final VoidCallback onTap;

  const _ViagemAtribuidaCard({required this.snapshot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final viagem = snapshot.viagem;
    final acessibilidade = snapshot.totalAcessibilidade > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        color: acessibilidade ? const Color(0xFFFFF8E1) : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${viagem['origem']} → ${viagem['destino_principal']}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  Chip(label: Text('Status: ${viagem['status']}')),
                  Chip(label: Text('Prioridade: ${viagem['prioridade']}')),
                  Chip(label: Text('${snapshot.totalPacientes} pacientes')),
                  if (acessibilidade)
                    Chip(
                      avatar: const Icon(Icons.accessible, size: 18),
                      label: Text(
                        '${snapshot.totalAcessibilidade} acessibilidade',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.fact_check),
                label: const Text('Iniciar Preparação'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LogisticaPreparacaoPage extends StatelessWidget {
  final String viagemId;
  final LogisticaOperacionalRepository repository;

  const LogisticaPreparacaoPage({
    super.key,
    required this.viagemId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return _SnapshotScaffold(
      title: 'Preparação da Viagem',
      viagemId: viagemId,
      repository: repository,
      builder: (context, snapshot) => [
        _ResumoOperacional(snapshot: snapshot),
        const SectionHeader(
          title: 'Pendências antes da saída',
          subtitle: 'Confira veículo, passageiros, acessibilidade e checklist.',
        ),
        _InfoCard(
          lines: [
            'Veículo: ${snapshot.viagem['veiculo_id_local']}',
            'Motorista: ${snapshot.viagem['motorista_id_local']}',
            'Checklist pré-uso: pendente',
            'KM de saída: pendente',
            if ((snapshot.viagem['observacoes_central']?.toString() ?? '')
                .isNotEmpty)
              'Central: ${snapshot.viagem['observacoes_central']}',
          ],
        ),
        ...snapshot.passageiros.map(
          (p) => _PacienteTile(snapshot: snapshot, passageiro: p),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LogisticaCheckinSaidaPage(
                viagemId: viagemId,
                repository: repository,
              ),
            ),
          ),
          icon: const Icon(Icons.speed),
          label: const Text('Avançar ao check-in'),
        ),
      ],
    );
  }
}

class LogisticaCheckinSaidaPage extends StatefulWidget {
  final String viagemId;
  final LogisticaOperacionalRepository repository;

  const LogisticaCheckinSaidaPage({
    super.key,
    required this.viagemId,
    required this.repository,
  });

  @override
  State<LogisticaCheckinSaidaPage> createState() =>
      _LogisticaCheckinSaidaPageState();
}

class _LogisticaCheckinSaidaPageState extends State<LogisticaCheckinSaidaPage> {
  final kmController = TextEditingController();
  bool checklist = false;

  @override
  void dispose() {
    kmController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    try {
      await widget.repository.confirmarSaida(
        viagemId: widget.viagemId,
        kmSaida: double.tryParse(kmController.text.replaceAll(',', '.')),
        checklistConcluido: checklist,
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LogisticaRotaIdaPage(
            viagemId: widget.viagemId,
            repository: widget.repository,
          ),
        ),
      );
    } on LogisticaValidationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SnapshotScaffold(
      title: 'Check-in de Saída',
      viagemId: widget.viagemId,
      repository: widget.repository,
      builder: (context, snapshot) => [
        _ResumoOperacional(snapshot: snapshot),
        _InfoCard(lines: ['Horário automático: ${DateTime.now()}']),
        TextField(
          controller: kmController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'KM de saída',
            prefixIcon: Icon(Icons.speed),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: CheckboxListTile(
            value: checklist,
            onChanged: (value) => setState(() => checklist = value ?? false),
            title: const Text('Checklist pré-uso concluído'),
          ),
        ),
        FilledButton.icon(
          onPressed: _confirmar,
          icon: const Icon(Icons.check_circle),
          label: const Text('Confirmar Saída'),
        ),
      ],
    );
  }
}

class LogisticaRotaIdaPage extends StatelessWidget {
  final String viagemId;
  final LogisticaOperacionalRepository repository;

  const LogisticaRotaIdaPage({
    super.key,
    required this.viagemId,
    required this.repository,
  });

  Future<void> _acao(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Registro salvo localmente.')));
    (context as Element).markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    return _SnapshotScaffold(
      title: 'Rota de Ida',
      viagemId: viagemId,
      repository: repository,
      builder: (context, snapshot) => [
        _ResumoOperacional(snapshot: snapshot),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Navegação externa será aberta em etapa futura.'),
            ),
          ),
          icon: const Icon(Icons.navigation),
          label: const Text('Abrir no Waze/Google Maps'),
        ),
        ...snapshot.passageiros.map(
          (p) => Card(
            child: ListTile(
              title: Text(pacienteNome(snapshot, p)),
              subtitle: Text('Status ida: ${p['status_ida']}'),
              trailing: Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    tooltip: 'Confirmar desembarque',
                    onPressed: () => _acao(
                      context,
                      () => repository.marcarPaciente(
                        viagemId: viagemId,
                        passageiroId: p['id_local']!.toString(),
                        status: StatusPacienteIda.desembarcado,
                      ),
                    ),
                    icon: const Icon(Icons.check_circle),
                  ),
                  IconButton(
                    tooltip: 'Ausente',
                    onPressed: () => _acao(
                      context,
                      () => repository.marcarPaciente(
                        viagemId: viagemId,
                        passageiroId: p['id_local']!.toString(),
                        status: StatusPacienteIda.ausente,
                      ),
                    ),
                    icon: const Icon(Icons.person_off),
                  ),
                  IconButton(
                    tooltip: 'Desistiu',
                    onPressed: () => _acao(
                      context,
                      () => repository.marcarPaciente(
                        viagemId: viagemId,
                        passageiroId: p['id_local']!.toString(),
                        status: StatusPacienteIda.desistiu,
                      ),
                    ),
                    icon: const Icon(Icons.cancel),
                  ),
                ],
              ),
            ),
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.atrasado),
          onPressed: () => repository.acionarPanico(viagemId),
          icon: const Icon(Icons.warning),
          label: const Text('Pânico'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await repository.iniciarEspera(viagemId);
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LogisticaEsperaPage(
                  viagemId: viagemId,
                  repository: repository,
                ),
              ),
            );
          },
          icon: const Icon(Icons.timer),
          label: const Text('Ir para Espera'),
        ),
      ],
    );
  }
}

class LogisticaEsperaPage extends StatelessWidget {
  final String viagemId;
  final LogisticaOperacionalRepository repository;

  const LogisticaEsperaPage({
    super.key,
    required this.viagemId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return _SnapshotScaffold(
      title: 'Em Espera',
      viagemId: viagemId,
      repository: repository,
      builder: (context, snapshot) => [
        _ResumoOperacional(snapshot: snapshot),
        _InfoCard(
          lines: [
            'Status: Em Espera',
            'Cronômetro: ${LogisticaCalculator.tempoEmEspera(DateTime.tryParse(snapshot.viagem['inicio_espera']?.toString() ?? ''), DateTime.now()).inMinutes} min',
            'Consulta: ${snapshot.viagem['horario_consulta'] ?? '-'}',
          ],
        ),
        OutlinedButton.icon(
          onPressed: () async {
            await repository.registrarDespesaMock(viagemId);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Despesa mockada registrada.')),
            );
          },
          icon: const Icon(Icons.local_gas_station),
          label: const Text('Registrar Abastecimento/Despesa'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LogisticaReembarquePage(
                viagemId: viagemId,
                repository: repository,
              ),
            ),
          ),
          icon: const Icon(Icons.group),
          label: const Text('Iniciar Reembarque de Retorno'),
        ),
      ],
    );
  }
}

class LogisticaReembarquePage extends StatefulWidget {
  final String viagemId;
  final LogisticaOperacionalRepository repository;

  const LogisticaReembarquePage({
    super.key,
    required this.viagemId,
    required this.repository,
  });

  @override
  State<LogisticaReembarquePage> createState() =>
      _LogisticaReembarquePageState();
}

class _LogisticaReembarquePageState extends State<LogisticaReembarquePage> {
  Future<void> _iniciarVolta() async {
    try {
      await widget.repository.iniciarRetorno(widget.viagemId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LogisticaRotaVoltaPage(
            viagemId: widget.viagemId,
            repository: widget.repository,
          ),
        ),
      );
    } on LogisticaValidationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SnapshotScaffold(
      title: 'Reembarque',
      viagemId: widget.viagemId,
      repository: widget.repository,
      builder: (context, snapshot) => [
        ...snapshot.passageiros.map(
          (p) => Card(
            child: ListTile(
              title: Text(pacienteNome(snapshot, p)),
              subtitle: Text('Retorno: ${p['status_volta']}'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Embarcado',
                    onPressed: () async {
                      await widget.repository.marcarRetorno(
                        passageiroId: p['id_local']!.toString(),
                        status: StatusPacienteVolta.embarcado,
                      );
                      setState(() {});
                    },
                    icon: const Icon(Icons.check_box),
                  ),
                  IconButton(
                    tooltip: 'Não retornou/justificado',
                    onPressed: () async {
                      await widget.repository.marcarRetorno(
                        passageiroId: p['id_local']!.toString(),
                        status: StatusPacienteVolta.justificado,
                      );
                      setState(() {});
                    },
                    icon: const Icon(Icons.rule),
                  ),
                  IconButton(
                    tooltip: 'Capturar comprovante',
                    onPressed: () => widget.repository.capturarComprovante(
                      widget.viagemId,
                      p['id_local']!.toString(),
                    ),
                    icon: const Icon(Icons.photo_camera),
                  ),
                ],
              ),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _iniciarVolta,
          icon: const Icon(Icons.keyboard_return),
          label: const Text('Iniciar Viagem de Volta'),
        ),
      ],
    );
  }
}

class LogisticaRotaVoltaPage extends StatelessWidget {
  final String viagemId;
  final LogisticaOperacionalRepository repository;

  const LogisticaRotaVoltaPage({
    super.key,
    required this.viagemId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return _SnapshotScaffold(
      title: 'Rota de Volta',
      viagemId: viagemId,
      repository: repository,
      builder: (context, snapshot) => [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.navigation),
          label: const Text('Navegação externa'),
        ),
        ...snapshot.passageiros.map(
          (p) => Card(
            child: ListTile(
              title: Text(pacienteNome(snapshot, p)),
              subtitle: Text('Desembarque retorno: ${p['status_volta']}'),
              trailing: IconButton(
                tooltip: 'Desembarque concluído',
                onPressed: () => repository.concluirDesembarqueVolta(
                  passageiroId: p['id_local']!.toString(),
                ),
                icon: const Icon(Icons.flag),
              ),
            ),
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.atrasado),
          onPressed: () => repository.acionarPanico(viagemId),
          icon: const Icon(Icons.warning),
          label: const Text('Pânico'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LogisticaEncerramentoPage(
                viagemId: viagemId,
                repository: repository,
              ),
            ),
          ),
          icon: const Icon(Icons.stop_circle),
          label: const Text('Encerrar viagem'),
        ),
      ],
    );
  }
}

class LogisticaEncerramentoPage extends StatefulWidget {
  final String viagemId;
  final LogisticaOperacionalRepository repository;

  const LogisticaEncerramentoPage({
    super.key,
    required this.viagemId,
    required this.repository,
  });

  @override
  State<LogisticaEncerramentoPage> createState() =>
      _LogisticaEncerramentoPageState();
}

class _LogisticaEncerramentoPageState extends State<LogisticaEncerramentoPage> {
  final kmFinalController = TextEditingController();

  @override
  void dispose() {
    kmFinalController.dispose();
    super.dispose();
  }

  Future<void> _concluir() async {
    try {
      await widget.repository.concluirViagem(
        viagemId: widget.viagemId,
        kmFinal: double.tryParse(kmFinalController.text.replaceAll(',', '.')),
        kmEsperado: 80,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viagem concluída localmente.')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } on LogisticaValidationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SnapshotScaffold(
      title: 'Encerramento',
      viagemId: widget.viagemId,
      repository: widget.repository,
      builder: (context, snapshot) => [
        _ResumoOperacional(snapshot: snapshot),
        _InfoCard(
          lines: [
            'Horário automático: ${DateTime.now()}',
            'KM inicial: ${snapshot.kmInicial ?? '-'}',
            'Despesas: R\$ ${snapshot.totalDespesas.toStringAsFixed(2)}',
            'Pacientes transportados: ${snapshot.transportados}',
            'Ocorrências: ${snapshot.ocorrencias.length}',
          ],
        ),
        TextField(
          controller: kmFinalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'KM final',
            prefixIcon: Icon(Icons.speed),
          ),
        ),
        FilledButton.icon(
          onPressed: _concluir,
          icon: const Icon(Icons.done_all),
          label: const Text('Concluir Viagem'),
        ),
      ],
    );
  }
}

class _SnapshotScaffold extends StatelessWidget {
  final String title;
  final String viagemId;
  final LogisticaOperacionalRepository repository;
  final List<Widget> Function(BuildContext, LogisticaTripSnapshot) builder;

  const _SnapshotScaffold({
    required this.title,
    required this.viagemId,
    required this.repository,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<LogisticaTripSnapshot>(
        future: repository.carregarSnapshot(viagemId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ...builder(context, snapshot.data!),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        },
      ),
    );
  }
}

class _ResumoOperacional extends StatelessWidget {
  final LogisticaTripSnapshot snapshot;

  const _ResumoOperacional({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${snapshot.viagem['origem']} → ${snapshot.viagem['destino_principal']}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                Chip(label: Text('Status: ${snapshot.status}')),
                Chip(label: Text('${snapshot.totalPacientes} pacientes')),
                if (snapshot.totalAcessibilidade > 0)
                  Chip(
                    label: Text(
                      '${snapshot.totalAcessibilidade} acessibilidade',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<String> lines;

  const _InfoCard({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines
              .map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _PacienteTile extends StatelessWidget {
  final LogisticaTripSnapshot snapshot;
  final Map<String, Object?> passageiro;

  const _PacienteTile({required this.snapshot, required this.passageiro});

  @override
  Widget build(BuildContext context) {
    final acessibilidade = pacienteAcessibilidade(snapshot, passageiro);
    return Card(
      child: ListTile(
        leading: Icon(
          acessibilidade == 'nenhuma' ? Icons.person : Icons.accessible,
          color: acessibilidade == 'nenhuma'
              ? AppColors.primary
              : Colors.orange.shade800,
        ),
        title: Text(pacienteNome(snapshot, passageiro)),
        subtitle: Text(
          [
            'Ida: ${passageiro['status_ida']}',
            'Volta: ${passageiro['status_volta']}',
            if (acessibilidade != 'nenhuma') 'Acessibilidade: $acessibilidade',
          ].join('\n'),
        ),
      ),
    );
  }
}

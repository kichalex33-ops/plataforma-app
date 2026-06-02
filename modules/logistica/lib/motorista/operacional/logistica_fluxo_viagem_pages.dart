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
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => LogisticaChecklistPage(
                  viagemId: widget.viagemId,
                  repository: widget.repository,
                  tipo: 'pre_uso',
                  titulo: 'Checklist Pré-Uso',
                ),
              ),
            );
            if (ok == true) setState(() => checklist = true);
          },
          icon: const Icon(Icons.fact_check),
          label: const Text('Preencher Checklist Pré-Uso'),
        ),
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
          onPressed: () async {
            await repository.acionarPanico(viagemId);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Central será notificada quando houver conexão.'),
              ),
            );
          },
          icon: const Icon(Icons.warning),
          label: const Text('Pânico'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LogisticaOcorrenciaPage(
                viagemId: viagemId,
                repository: repository,
              ),
            ),
          ),
          icon: const Icon(Icons.report_problem),
          label: const Text('Registrar Ocorrência'),
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LogisticaDespesaPage(
                viagemId: viagemId,
                repository: repository,
              ),
            ),
          ),
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
          onPressed: () async {
            await repository.acionarPanico(viagemId);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Central será notificada quando houver conexão.'),
              ),
            );
          },
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
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LogisticaChecklistPage(
                viagemId: widget.viagemId,
                repository: widget.repository,
                tipo: 'pos_uso',
                titulo: 'Checklist Pós-Uso',
              ),
            ),
          ),
          icon: const Icon(Icons.fact_check),
          label: const Text('Preencher Checklist Pós-Uso'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LogisticaHistoricoPage(
                viagemId: widget.viagemId,
                repository: widget.repository,
              ),
            ),
          ),
          icon: const Icon(Icons.history),
          label: const Text('Histórico da Viagem'),
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

class LogisticaChecklistPage extends StatefulWidget {
  final String viagemId;
  final LogisticaOperacionalRepository repository;
  final String tipo;
  final String titulo;

  const LogisticaChecklistPage({
    super.key,
    required this.viagemId,
    required this.repository,
    required this.tipo,
    required this.titulo,
  });

  @override
  State<LogisticaChecklistPage> createState() => _LogisticaChecklistPageState();
}

class _LogisticaChecklistPageState extends State<LogisticaChecklistPage> {
  late final Map<String, bool> itens = {for (final item in _itens) item: true};
  final observacaoController = TextEditingController();
  final fotoController = TextEditingController();

  List<String> get _itens => widget.tipo == 'pre_uso'
      ? const [
          'Pneus',
          'Faróis',
          'Setas',
          'Freios',
          'Óleo',
          'Combustível',
          'Limpeza',
          'CRLV',
          'CNH',
          'Documentação obrigatória',
          'Macaco',
          'Triângulo',
          'Extintor',
          'Estepe',
          'Cadeira de rodas',
          'Maca',
        ]
      : const [
          'Limpeza',
          'Danos observados',
          'Combustível remanescente',
          'Observações finais',
        ];

  @override
  void dispose() {
    observacaoController.dispose();
    fotoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    await widget.repository.registrarChecklist(
      viagemId: widget.viagemId,
      tipo: widget.tipo,
      itens: itens,
      observacao: observacaoController.text.trim(),
      fotoPath: fotoController.text.trim().isEmpty
          ? null
          : fotoController.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(
            title: 'Itens de inspeção',
            subtitle:
                'Marque não ok quando houver pendência e registre observação.',
          ),
          ...itens.keys.map(
            (item) => Card(
              child: SwitchListTile(
                value: itens[item] ?? true,
                onChanged: (value) => setState(() => itens[item] = value),
                title: Text(item),
                subtitle: Text((itens[item] ?? true) ? 'Ok' : 'Não ok'),
              ),
            ),
          ),
          TextField(
            controller: observacaoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observação',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: fotoController,
            decoration: const InputDecoration(
              labelText: 'Foto opcional',
              prefixIcon: Icon(Icons.photo_camera),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.save),
            label: const Text('Salvar Checklist'),
          ),
        ],
      ),
    );
  }
}

class LogisticaDespesaPage extends StatefulWidget {
  final String viagemId;
  final LogisticaOperacionalRepository repository;

  const LogisticaDespesaPage({
    super.key,
    required this.viagemId,
    required this.repository,
  });

  @override
  State<LogisticaDespesaPage> createState() => _LogisticaDespesaPageState();
}

class _LogisticaDespesaPageState extends State<LogisticaDespesaPage> {
  bool abastecimento = true;
  String tipoDespesa = 'pedágio';
  final postoController = TextEditingController();
  final litrosController = TextEditingController();
  final valorController = TextEditingController();
  final descricaoController = TextEditingController();
  final fotoController = TextEditingController();

  @override
  void dispose() {
    postoController.dispose();
    litrosController.dispose();
    valorController.dispose();
    descricaoController.dispose();
    fotoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    try {
      final valor =
          double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0;
      if (abastecimento) {
        final litros =
            double.tryParse(litrosController.text.replaceAll(',', '.')) ?? 0;
        final result = await widget.repository.registrarAbastecimento(
          viagemId: widget.viagemId,
          posto: postoController.text.trim(),
          litros: litros,
          valorTotal: valor,
          fotoCupomPath: fotoController.text.trim().isEmpty
              ? null
              : fotoController.text.trim(),
          observacao: descricaoController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Valor por litro: R\$ ${result.valorPorLitro.toStringAsFixed(2)}',
            ),
          ),
        );
      } else {
        await widget.repository.registrarDespesaGeral(
          viagemId: widget.viagemId,
          tipo: tipoDespesa,
          valor: valor,
          descricao: descricaoController.text.trim(),
          comprovantePath: fotoController.text.trim().isEmpty
              ? null
              : fotoController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } on LogisticaValidationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abastecimento e Despesas')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: SwitchListTile(
              value: abastecimento,
              onChanged: (value) => setState(() => abastecimento = value),
              title: Text(abastecimento ? 'Abastecimento' : 'Despesa geral'),
            ),
          ),
          if (!abastecimento)
            DropdownButtonFormField<String>(
              initialValue: tipoDespesa,
              decoration: const InputDecoration(labelText: 'Tipo de despesa'),
              items:
                  const [
                        'pedágio',
                        'estacionamento',
                        'alimentação autorizada',
                        'manutenção emergencial',
                        'outro',
                      ]
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
              onChanged: (value) =>
                  setState(() => tipoDespesa = value ?? tipoDespesa),
            ),
          if (abastecimento)
            TextField(
              controller: postoController,
              decoration: const InputDecoration(labelText: 'Posto'),
            ),
          if (abastecimento)
            TextField(
              controller: litrosController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Litros'),
            ),
          TextField(
            controller: valorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor total'),
          ),
          TextField(
            controller: descricaoController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observação/descrição',
            ),
          ),
          TextField(
            controller: fotoController,
            decoration: const InputDecoration(
              labelText: 'Foto do cupom/comprovante',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.save),
            label: const Text('Salvar Registro'),
          ),
        ],
      ),
    );
  }
}

class LogisticaOcorrenciaPage extends StatefulWidget {
  final String viagemId;
  final LogisticaOperacionalRepository repository;

  const LogisticaOcorrenciaPage({
    super.key,
    required this.viagemId,
    required this.repository,
  });

  @override
  State<LogisticaOcorrenciaPage> createState() =>
      _LogisticaOcorrenciaPageState();
}

class _LogisticaOcorrenciaPageState extends State<LogisticaOcorrenciaPage> {
  TipoOcorrencia tipo = TipoOcorrencia.atraso;
  final descricaoController = TextEditingController();
  final localizacaoController = TextEditingController();
  final fotoController = TextEditingController();

  @override
  void dispose() {
    descricaoController.dispose();
    localizacaoController.dispose();
    fotoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    await widget.repository.registrarOcorrencia(
      viagemId: widget.viagemId,
      tipo: tipo,
      descricao: descricaoController.text.trim(),
      fotoPath: fotoController.text.trim().isEmpty
          ? null
          : fotoController.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Ocorrência')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          DropdownButtonFormField<TipoOcorrencia>(
            initialValue: tipo,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: TipoOcorrencia.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.dbValue)),
                )
                .toList(),
            onChanged: (value) => setState(() => tipo = value ?? tipo),
          ),
          TextField(
            controller: descricaoController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          TextField(
            controller: localizacaoController,
            decoration: const InputDecoration(
              labelText: 'Localização disponível',
            ),
          ),
          TextField(
            controller: fotoController,
            decoration: const InputDecoration(labelText: 'Foto opcional'),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.save),
            label: const Text('Salvar Ocorrência'),
          ),
        ],
      ),
    );
  }
}

class LogisticaHistoricoPage extends StatelessWidget {
  final String viagemId;
  final LogisticaOperacionalRepository repository;

  const LogisticaHistoricoPage({
    super.key,
    required this.viagemId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Histórico da Viagem'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Checklists'),
              Tab(text: 'Despesas'),
              Tab(text: 'Ocorrências'),
              Tab(text: 'Comprovantes'),
              Tab(text: 'Sync'),
            ],
          ),
        ),
        body: FutureBuilder<List<Map<String, Object?>>>(
          future: repository.listarHistorico(viagemId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final itens = snapshot.data!;
            return TabBarView(
              children: [
                _HistoricoLista(itens: itens, categoria: 'checklist'),
                _HistoricoLista(itens: itens, categoria: 'despesa'),
                _HistoricoLista(itens: itens, categoria: 'ocorrencia'),
                _HistoricoLista(itens: itens, categoria: 'comprovante'),
                _HistoricoLista(itens: itens, categoria: 'sync'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoricoLista extends StatelessWidget {
  final List<Map<String, Object?>> itens;
  final String categoria;

  const _HistoricoLista({required this.itens, required this.categoria});

  @override
  Widget build(BuildContext context) {
    final filtrados = itens
        .where((item) => item['categoria'] == categoria)
        .toList();
    if (filtrados.isEmpty) {
      return const Center(child: Text('Nenhum registro encontrado.'));
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: filtrados
          .map(
            (item) => Card(
              child: ListTile(
                title: Text(
                  item['tipo']?.toString() ??
                      item['tipo_evento']?.toString() ??
                      categoria,
                ),
                subtitle: Text(
                  item['descricao']?.toString() ??
                      item['observacao']?.toString() ??
                      item['created_at']?.toString() ??
                      '',
                ),
              ),
            ),
          )
          .toList(),
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

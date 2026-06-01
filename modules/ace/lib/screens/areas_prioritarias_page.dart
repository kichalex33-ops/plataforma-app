import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/area_prioritaria_model.dart';
import '../services/gps_service.dart';

class AreasPrioritariasPage extends StatefulWidget {
  const AreasPrioritariasPage({super.key});

  @override
  State<AreasPrioritariasPage> createState() => _AreasPrioritariasPageState();
}

class _AreasPrioritariasPageState extends State<AreasPrioritariasPage> {
  final nomeController = TextEditingController();
  final enderecoController = TextEditingController();
  final observacoesController = TextEditingController();

  List<AreaPrioritariaModel> areas = [];
  Map<String, String> config = {};
  String tipoRisco = 'Ambiental';
  String grauRisco = 'Medio';
  String motivoPrioridade = 'Risco ambiental';
  String status = 'Aberta';
  int gravidade = 3;
  int urgencia = 3;
  int tendencia = 3;
  bool salvando = false;

  final tiposRisco = const [
    'Ambiental',
    'Entomologico',
    'Sanitario',
    'Social',
    'Epidemiologico',
  ];

  final grausRisco = const ['Baixo', 'Medio', 'Alto', 'Prioritario'];

  final motivos = const [
    'Risco ambiental',
    'Foco positivo anterior',
    'Imovel fechado recorrente',
    'Saneamento inadequado',
    'Presenca de vetor ou reservatorio',
    'Vulnerabilidade social',
    'Equipamento coletivo',
    'Area sem cobertura',
    'Denuncia ou comunicado',
  ];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    nomeController.dispose();
    enderecoController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    final lista = await DatabaseHelper.instance.listarAreasPrioritarias();
    final configuracao = await DatabaseHelper.instance.carregarConfiguracao();

    if (!mounted) return;

    setState(() {
      areas = lista;
      config = configuracao;
    });
  }

  String formatarDataHora(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  Color corGrau(String grau) {
    if (grau == 'Prioritario') return AppColors.atrasado;
    if (grau == 'Alto') return AppColors.relatorios;
    if (grau == 'Medio') return AppColors.vencendo;
    return AppColors.emDia;
  }

  Future<void> salvarArea() async {
    if (nomeController.text.trim().isEmpty ||
        enderecoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe nome e endereco da area.')),
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final posicao = await GPSService.obterLocalizacaoObrigatoria();
      final agora = DateTime.now();

      await DatabaseHelper.instance.inserirAreaPrioritaria(
        AreaPrioritariaModel(
          nome: nomeController.text.trim(),
          endereco: enderecoController.text.trim(),
          tipoRisco: tipoRisco,
          grauRisco: grauRisco,
          motivoPrioridade: motivoPrioridade,
          municipio: config['municipio'] ?? '',
          agente: config['agente'] ?? '',
          dataRegistro: formatarDataHora(agora),
          status: status,
          observacoes: observacoesController.text.trim(),
          gravidade: gravidade,
          urgencia: urgencia,
          tendencia: tendencia,
          latitude: posicao.latitude,
          longitude: posicao.longitude,
        ),
      );

      nomeController.clear();
      enderecoController.clear();
      observacoesController.clear();

      await carregarDados();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Area prioritaria registrada.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          salvando = false;
        });
      }
    }
  }

  Future<void> excluirArea(AreaPrioritariaModel area) async {
    if (area.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir area'),
        content: Text('Excluir "${area.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseHelper.instance.excluirAreaPrioritaria(area.id!);
      await carregarDados();
    }
  }

  Widget construirCabecalho() {
    final prioritarias = areas
        .where(
          (area) => area.grauRisco == 'Prioritario' || area.grauRisco == 'Alto',
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.relatorios,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.priority_high, color: Colors.white, size: 34),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risco territorial',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${areas.length} areas registradas - $prioritarias criticas',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget construirFormulario() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da area ou ponto',
                prefixIcon: Icon(Icons.edit_location_alt),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: enderecoController,
              decoration: const InputDecoration(
                labelText: 'Endereco ou referencia',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DropdownTexto(
              label: 'Tipo de risco',
              icon: Icons.category,
              value: tipoRisco,
              values: tiposRisco,
              onChanged: (value) => setState(() => tipoRisco = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _DropdownTexto(
              label: 'Grau de risco',
              icon: Icons.traffic,
              value: grauRisco,
              values: grausRisco,
              onChanged: (value) => setState(() => grauRisco = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _DropdownTexto(
              label: 'Motivo de prioridade',
              icon: Icons.report_problem,
              value: motivoPrioridade,
              values: motivos,
              onChanged: (value) => setState(() => motivoPrioridade = value),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _DropdownNumero(
                    label: 'G',
                    value: gravidade,
                    onChanged: (value) => setState(() => gravidade = value),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DropdownNumero(
                    label: 'U',
                    value: urgencia,
                    onChanged: (value) => setState(() => urgencia = value),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DropdownNumero(
                    label: 'T',
                    value: tendencia,
                    onChanged: (value) => setState(() => tendencia = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Prioridade GUT: ${gravidade * urgencia * tendencia}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: observacoesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observacoes tecnicas',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.relatorios,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 58),
              ),
              onPressed: salvando ? null : salvarArea,
              icon: Icon(salvando ? Icons.my_location : Icons.add_location_alt),
              label: Text(
                salvando ? 'Capturando GPS...' : 'Registrar area prioritaria',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirLista() {
    if (areas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Nenhuma area prioritaria registrada.'),
        ),
      );
    }

    return Column(
      children: areas.map((area) {
        final cor = corGrau(area.grauRisco);
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border(left: BorderSide(color: cor, width: 5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      area.nome,
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    onPressed: () => excluirArea(area),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
              _LinhaArea(icon: Icons.place, texto: area.endereco),
              _LinhaArea(icon: Icons.category, texto: area.tipoRisco),
              _LinhaArea(
                icon: Icons.report_problem,
                texto: area.motivoPrioridade,
              ),
              _LinhaArea(
                icon: Icons.person,
                texto: area.agente.isEmpty ? 'ACE nao informado' : area.agente,
              ),
              _LinhaArea(icon: Icons.calendar_month, texto: area.dataRegistro),
              _LinhaArea(
                icon: Icons.my_location,
                texto:
                    '${area.latitude.toStringAsFixed(6)}, ${area.longitude.toStringAsFixed(6)}',
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ChipArea(texto: area.grauRisco, cor: cor),
                  _ChipArea(
                    texto: 'GUT ${area.prioridadeGUT}',
                    cor: AppColors.primary,
                  ),
                  _ChipArea(texto: area.status, cor: AppColors.textMuted),
                ],
              ),
              if (area.observacoes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  area.observacoes,
                  style: const TextStyle(color: AppColors.textStrong),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Risco Territorial')),
      body: RefreshIndicator(
        onRefresh: carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            construirCabecalho(),
            const SizedBox(height: AppSpacing.lg),
            construirFormulario(),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Areas registradas',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            construirLista(),
          ],
        ),
      ),
    );
  }
}

class _DropdownTexto extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _DropdownTexto({
    required this.label,
    required this.icon,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: values.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _DropdownNumero extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _DropdownNumero({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [1, 2, 3, 4, 5].map((item) {
        return DropdownMenuItem(value: item, child: Text(item.toString()));
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _LinhaArea extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _LinhaArea({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipArea extends StatelessWidget {
  final String texto;
  final Color cor;

  const _ChipArea({required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/lira_lia_visita_model.dart';
import '../models/rg_quarteirao_model.dart';
import '../services/gps_service.dart';
import '../utils/epidemiological_calendar.dart';

class LiraLiaPage extends StatefulWidget {
  const LiraLiaPage({super.key});

  @override
  State<LiraLiaPage> createState() => _LiraLiaPageState();
}

class _LiraLiaPageState extends State<LiraLiaPage> {
  final previstosController = TextEditingController();
  final trabalhadosController = TextEditingController();
  final fechadosController = TextEditingController();
  final focosController = TextEditingController();
  final observacoesController = TextEditingController();

  List<RGQuarteiraoModel> quarteiroes = [];
  List<LiraLiaVisitaModel> visitas = [];
  Map<String, String> config = {};
  RGQuarteiraoModel? quarteiraoSelecionado;
  String tipoLevantamento = 'LIRAa';
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    previstosController.dispose();
    trabalhadosController.dispose();
    fechadosController.dispose();
    focosController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    final rg = await DatabaseHelper.instance.listarRGQuarteiroes();
    final lista = await DatabaseHelper.instance.listarLiraLiaVisitas();
    final configuracao = await DatabaseHelper.instance.carregarConfiguracao();

    if (!mounted) return;

    setState(() {
      quarteiroes = rg;
      visitas = lista;
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

  Future<void> salvarVisita() async {
    if (quarteiraoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o quarteirao RG.')),
      );
      return;
    }

    final previstos = int.tryParse(previstosController.text.trim()) ?? 0;
    final trabalhados = int.tryParse(trabalhadosController.text.trim()) ?? 0;
    final fechados = int.tryParse(fechadosController.text.trim()) ?? 0;
    final focos = int.tryParse(focosController.text.trim()) ?? 0;

    if (previstos == 0 && trabalhados == 0 && fechados == 0 && focos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe pelo menos um dado da visita.')),
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final posicao = await GPSService.obterLocalizacaoObrigatoria();
      final agora = DateTime.now();

      await DatabaseHelper.instance.inserirLiraLiaVisita(
        LiraLiaVisitaModel(
          rgQuarteiraoId: quarteiraoSelecionado!.id,
          rgQuarteiraoCodigo: quarteiraoSelecionado!.codigo,
          tipoLevantamento: tipoLevantamento,
          municipio: config['municipio'] ?? '',
          agente: config['agente'] ?? '',
          dataRegistro: formatarDataHora(agora),
          imoveisPrevistos: previstos,
          imoveisTrabalhados: trabalhados,
          imoveisFechados: fechados,
          focosPositivos: focos,
          observacoes: observacoesController.text.trim(),
          latitude: posicao.latitude,
          longitude: posicao.longitude,
        ),
      );

      previstosController.clear();
      trabalhadosController.clear();
      fechadosController.clear();
      focosController.clear();
      observacoesController.clear();

      setState(() {
        quarteiraoSelecionado = null;
      });

      await carregarDados();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro LIRA/LIA salvo.')));
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

  Widget construirCabecalho() {
    final positivos = visitas.where((item) => item.focosPositivos > 0).length;
    final ciclo = EpidemiologicalCalendar.cicloMunicipioAtual();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.fact_check, color: Colors.white, size: 34),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIRA/LIA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${visitas.length} registros - $positivos com foco',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (ciclo != null)
                  Text(
                    '${ciclo.titulo} - ${ciclo.periodo} (${ciclo.semanas})',
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
            DropdownButtonFormField<String>(
              initialValue: tipoLevantamento,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.assignment),
              ),
              items: const [
                DropdownMenuItem(value: 'LIRAa', child: Text('LIRAa')),
                DropdownMenuItem(value: 'LIA', child: Text('LIA')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => tipoLevantamento = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              initialValue: quarteiraoSelecionado?.id,
              decoration: const InputDecoration(
                labelText: 'Quarteirao RG',
                prefixIcon: Icon(Icons.grid_view),
              ),
              items: quarteiroes.where((item) => item.id != null).map((item) {
                return DropdownMenuItem(
                  value: item.id!,
                  child: Text('Q ${item.codigo} - ponto ${item.ordem}'),
                );
              }).toList(),
              onChanged: (id) {
                if (id == null) return;
                setState(() {
                  for (final item in quarteiroes) {
                    if (item.id == id) {
                      quarteiraoSelecionado = item;
                      break;
                    }
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _NumeroField(
                    controller: previstosController,
                    label: 'Previstos',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumeroField(
                    controller: trabalhadosController,
                    label: 'Trabalhados',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _NumeroField(
                    controller: fechadosController,
                    label: 'Fechados',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumeroField(
                    controller: focosController,
                    label: 'Focos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: observacoesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observacoes'),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 58),
              ),
              onPressed: salvando ? null : salvarVisita,
              icon: Icon(salvando ? Icons.my_location : Icons.save),
              label: Text(
                salvando ? 'Capturando GPS...' : 'Salvar registro',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirHistorico() {
    if (visitas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Nenhum registro LIRA/LIA salvo.'),
        ),
      );
    }

    return Column(
      children: visitas.map((item) {
        final cor = item.focosPositivos > 0
            ? AppColors.atrasado
            : AppColors.emDia;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border(left: BorderSide(color: cor, width: 5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.tipoLevantamento} - Quarteirao ${item.rgQuarteiraoCodigo}',
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _LinhaLira(icon: Icons.calendar_month, texto: item.dataRegistro),
              _LinhaLira(icon: Icons.person, texto: item.agente),
              _LinhaLira(
                icon: Icons.home,
                texto:
                    'Trabalhados: ${item.imoveisTrabalhados}/${item.imoveisPrevistos} - Fechados: ${item.imoveisFechados}',
              ),
              _LinhaLira(
                icon: Icons.science,
                texto: 'Focos positivos: ${item.focosPositivos}',
              ),
              _LinhaLira(
                icon: Icons.my_location,
                texto:
                    '${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}',
              ),
              if (item.observacoes.isNotEmpty)
                _LinhaLira(icon: Icons.notes, texto: item.observacoes),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LIRA/LIA')),
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
              'Historico',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            construirHistorico(),
          ],
        ),
      ),
    );
  }
}

class _NumeroField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _NumeroField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _LinhaLira extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _LinhaLira({required this.icon, required this.texto});

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

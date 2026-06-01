import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/atividade_quarteirao_model.dart';
import '../models/quarteirao_model.dart';
import '../services/gps_service.dart';

class QuarteiroesPage extends StatefulWidget {
  const QuarteiroesPage({super.key});

  @override
  State<QuarteiroesPage> createState() => _QuarteiroesPageState();
}

class _QuarteiroesPageState extends State<QuarteiroesPage> {
  final numeroController = TextEditingController();
  final localidadeController = TextEditingController();
  final totalController = TextEditingController();
  final residenciasController = TextEditingController();
  final comerciosController = TextEditingController();
  final pesController = TextEditingController();
  final outrosController = TextEditingController();

  final visitadosController = TextEditingController();
  final fechadosController = TextEditingController();
  final recusadosController = TextEditingController();
  final coletasController = TextEditingController();
  final positivasController = TextEditingController();
  final negativasController = TextEditingController();
  final observacoesController = TextEditingController();

  List<QuarteiraoModel> quarteiroes = [];
  List<AtividadeQuarteiraoModel> atividades = [];
  Map<String, String> config = {};
  QuarteiraoModel? selecionado;
  String atividadeSelecionada = 'LI+T';
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    numeroController.dispose();
    localidadeController.dispose();
    totalController.dispose();
    residenciasController.dispose();
    comerciosController.dispose();
    pesController.dispose();
    outrosController.dispose();
    visitadosController.dispose();
    fechadosController.dispose();
    recusadosController.dispose();
    coletasController.dispose();
    positivasController.dispose();
    negativasController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    final qs = await DatabaseHelper.instance.listarQuarteiroes();
    final hist = await DatabaseHelper.instance.listarAtividadesQuarteirao();
    final cfg = await DatabaseHelper.instance.carregarConfiguracao();

    if (!mounted) return;

    setState(() {
      quarteiroes = qs;
      atividades = hist;
      config = cfg;
      if (selecionado != null) {
        selecionado = qs
            .where((item) => item.id == selecionado!.id)
            .cast<QuarteiraoModel?>()
            .firstOrNull;
      }
    });
  }

  int inteiro(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  String formatarAgora() {
    final data = DateTime.now();
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  Future<void> salvarQuarteirao() async {
    final numero = numeroController.text.trim();
    final localidade = localidadeController.text.trim();

    if (numero.isEmpty || localidade.isEmpty) {
      mostrarMensagem('Informe numero e localidade.');
      return;
    }

    setState(() => salvando = true);

    try {
      await DatabaseHelper.instance.inserirQuarteirao(
        QuarteiraoModel(
          numero: numero,
          localidade: localidade,
          totalImoveis: inteiro(totalController),
          residencias: inteiro(residenciasController),
          comercios: inteiro(comerciosController),
          pontosEstrategicos: inteiro(pesController),
          outros: inteiro(outrosController),
          status: 'Nao iniciado',
          atividadeAtual: 'Rotina',
        ),
      );

      numeroController.clear();
      localidadeController.clear();
      totalController.clear();
      residenciasController.clear();
      comerciosController.clear();
      pesController.clear();
      outrosController.clear();
      await carregarDados();
      mostrarMensagem('Quarteirao cadastrado.');
    } catch (error) {
      mostrarMensagem('Erro ao salvar quarteirao: $error');
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  Future<void> registrarAtividade() async {
    final quarteirao = selecionado;
    final id = quarteirao?.id;

    if (quarteirao == null || id == null) {
      mostrarMensagem('Selecione um quarteirao.');
      return;
    }

    setState(() => salvando = true);

    try {
      final posicao = await GPSService.obterLocalizacaoObrigatoria();
      final visitados = inteiro(visitadosController);
      final fechados = inteiro(fechadosController);
      final recusados = inteiro(recusadosController);
      final pendentes =
          quarteirao.totalImoveis - visitados - fechados - recusados;

      await DatabaseHelper.instance.inserirAtividadeQuarteirao(
        AtividadeQuarteiraoModel(
          quarteiraoId: id,
          quarteiraoNumero: quarteirao.numero,
          localidade: quarteirao.localidade,
          dataAtividade: formatarAgora(),
          agente: config['agente'] ?? '',
          atividade: atividadeSelecionada,
          imoveisPrevistos: quarteirao.totalImoveis,
          imoveisVisitados: visitados,
          imoveisFechados: fechados,
          imoveisRecusados: recusados,
          imoveisPendentes: pendentes < 0 ? 0 : pendentes,
          coletasRealizadas: inteiro(coletasController),
          coletasPositivas: inteiro(positivasController),
          coletasNegativas: inteiro(negativasController),
          observacoes: observacoesController.text.trim(),
          latitude: posicao.latitude,
          longitude: posicao.longitude,
        ),
      );

      visitadosController.clear();
      fechadosController.clear();
      recusadosController.clear();
      coletasController.clear();
      positivasController.clear();
      negativasController.clear();
      observacoesController.clear();
      await carregarDados();
      mostrarMensagem('Atividade registrada.');
    } catch (error) {
      mostrarMensagem(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  void mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Widget construirCadastro() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cadastrar quarteirao',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: numeroController,
                    decoration: const InputDecoration(labelText: 'Numero'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: localidadeController,
                    decoration: const InputDecoration(labelText: 'Localidade'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _NumeroField(
                    controller: totalController,
                    label: 'Total',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumeroField(
                    controller: residenciasController,
                    label: 'Resid.',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumeroField(
                    controller: comerciosController,
                    label: 'Com.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _NumeroField(controller: pesController, label: 'PEs'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumeroField(
                    controller: outrosController,
                    label: 'Outros',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: salvando ? null : salvarQuarteirao,
              icon: const Icon(Icons.save),
              label: const Text('Salvar quarteirao'),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirAtividade() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Registrar atividade',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              initialValue: selecionado?.id,
              decoration: const InputDecoration(labelText: 'Quarteirao'),
              items: quarteiroes.where((item) => item.id != null).map((item) {
                return DropdownMenuItem(
                  value: item.id,
                  child: Text('${item.localidade} - Q${item.numero}'),
                );
              }).toList(),
              onChanged: (id) {
                setState(() {
                  selecionado = quarteiroes.firstWhere((item) => item.id == id);
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: atividadeSelecionada,
              decoration: const InputDecoration(labelText: 'Atividade'),
              items: const [
                DropdownMenuItem(value: 'LI+T', child: Text('LI+T')),
                DropdownMenuItem(value: 'LIRAa', child: Text('LIRAa')),
                DropdownMenuItem(value: 'LIA', child: Text('LIA')),
                DropdownMenuItem(value: 'PVE', child: Text('PVE')),
                DropdownMenuItem(value: 'Rotina', child: Text('Rotina')),
                DropdownMenuItem(value: 'Bloqueio', child: Text('Bloqueio')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => atividadeSelecionada = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _NumeroField(
                    controller: visitadosController,
                    label: 'Visitados',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumeroField(
                    controller: fechadosController,
                    label: 'Fechados',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumeroField(
                    controller: recusadosController,
                    label: 'Recusados',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _NumeroField(
                    controller: coletasController,
                    label: 'Coletas',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumeroField(
                    controller: positivasController,
                    label: 'Positivas',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumeroField(
                    controller: negativasController,
                    label: 'Negativas',
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
              onPressed: salvando ? null : registrarAtividade,
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('Registrar com GPS'),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirLista() {
    if (quarteiroes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Nenhum quarteirao cadastrado.'),
        ),
      );
    }

    return Column(
      children: quarteiroes.map((q) {
        final cor = q.status == 'Concluido'
            ? AppColors.emDia
            : q.status == 'Em andamento'
            ? AppColors.vencendo
            : AppColors.textMuted;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cor.withValues(alpha: 0.14),
              child: Text(
                q.numero,
                style: TextStyle(color: cor, fontWeight: FontWeight.w800),
              ),
            ),
            title: Text('${q.localidade} - Quarteirao ${q.numero}'),
            subtitle: Text(
              '${q.totalImoveis} imoveis | ${q.atividadeAtual} | ${q.status}',
            ),
            trailing: Text(q.ultimaDataTrabalhada ?? '-'),
          ),
        );
      }).toList(),
    );
  }

  Widget construirHistorico() {
    if (atividades.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historico recente',
          style: TextStyle(
            color: AppColors.textStrong,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...atividades.take(8).map((a) {
          return Card(
            child: ListTile(
              title: Text('${a.localidade} - Q${a.quarteiraoNumero}'),
              subtitle: Text(
                '${a.atividade} | visitados ${a.imoveisVisitados}, fechados ${a.imoveisFechados}, recusados ${a.imoveisRecusados} | coletas ${a.coletasRealizadas}',
              ),
              trailing: Text(a.dataAtividade),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quarteiroes')),
      body: RefreshIndicator(
        onRefresh: carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Row(
                children: [
                  Icon(Icons.grid_view, color: Colors.white, size: 34),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Controle territorial por quarteirao',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            construirCadastro(),
            const SizedBox(height: AppSpacing.lg),
            construirAtividade(),
            const SizedBox(height: AppSpacing.lg),
            construirLista(),
            const SizedBox(height: AppSpacing.lg),
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

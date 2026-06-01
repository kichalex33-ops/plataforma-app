import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/ace_profile_model.dart';
import '../models/territorio_models.dart';
import '../repositories/atribuicao_setor_repository.dart';
import '../repositories/localidade_repository.dart';
import '../repositories/quarteirao_repository.dart';
import '../repositories/setor_repository.dart';

class TerritorioSupervisorPage extends StatefulWidget {
  final String? supervisorId;
  final String? municipio;

  const TerritorioSupervisorPage({super.key, this.supervisorId, this.municipio});

  @override
  State<TerritorioSupervisorPage> createState() =>
      _TerritorioSupervisorPageState();
}

class _TerritorioSupervisorPageState extends State<TerritorioSupervisorPage> {
  final localidadeRepo = LocalidadeRepository();
  final setorRepo = SetorRepository();
  final quarteiraoRepo = QuarteiraoRepository();
  final atribuicaoRepo = AtribuicaoSetorRepository();

  final localidadeController = TextEditingController();
  final setorCodigoController = TextEditingController();
  final setorNomeController = TextEditingController();
  final quarteiraoCodigoController = TextEditingController();
  final ordemController = TextEditingController();
  final imoveisController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  final observacaoAtribuicaoController = TextEditingController();

  List<LocalidadeModel> localidades = [];
  List<SetorOperacionalModel> setores = [];
  List<QuarteiraoOperacionalModel> quarteiroes = [];
  List<ACEProfileModel> perfis = [];
  LocalidadeModel? localidadeSelecionada;
  SetorOperacionalModel? setorSelecionado;
  ACEProfileModel? aceSelecionado;
  bool carregando = true;

  String get municipioId => (widget.municipio ?? 'municipio_local')
      .trim()
      .toLowerCase()
      .replaceAll(' ', '_');

  String get supervisorId => widget.supervisorId ?? 'supervisor_local';

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  void dispose() {
    localidadeController.dispose();
    setorCodigoController.dispose();
    setorNomeController.dispose();
    quarteiraoCodigoController.dispose();
    ordemController.dispose();
    imoveisController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    observacaoAtribuicaoController.dispose();
    super.dispose();
  }

  Future<void> carregar() async {
    final listaLocalidades = await localidadeRepo.listar(municipioId: municipioId);
    final listaPerfis = await DatabaseHelper.instance.listarPerfisACE();
    final localidadeFiltrada = localidadeSelecionada == null
        ? <LocalidadeModel>[]
        : listaLocalidades
              .where((item) => item.sync.id == localidadeSelecionada!.sync.id)
              .toList();
    final localidadeAtual = localidadeSelecionada == null
        ? (listaLocalidades.isEmpty ? null : listaLocalidades.first)
        : (localidadeFiltrada.isEmpty ? null : localidadeFiltrada.first);
    final listaSetores = localidadeAtual == null
        ? <SetorOperacionalModel>[]
        : await setorRepo.listarPorLocalidade(localidadeAtual.sync.id);
    final setorFiltrado = setorSelecionado == null
        ? <SetorOperacionalModel>[]
        : listaSetores
              .where((item) => item.sync.id == setorSelecionado!.sync.id)
              .toList();
    final setorAtual = setorSelecionado == null
        ? (listaSetores.isEmpty ? null : listaSetores.first)
        : (setorFiltrado.isEmpty ? null : setorFiltrado.first);
    final listaQuarteiroes = setorAtual == null
        ? <QuarteiraoOperacionalModel>[]
        : await quarteiraoRepo.listarPorSetor(setorAtual.sync.id);

    if (!mounted) return;
    setState(() {
      localidades = listaLocalidades;
      perfis = listaPerfis;
      localidadeSelecionada = localidadeAtual;
      setores = listaSetores;
      setorSelecionado = setorAtual;
      quarteiroes = listaQuarteiroes;
      aceSelecionado = perfis.isEmpty ? null : aceSelecionado ?? perfis.first;
      carregando = false;
    });
  }

  Future<void> criarLocalidade() async {
    final nome = localidadeController.text.trim();
    if (nome.isEmpty) return;

    await localidadeRepo.criar(
      municipioId: municipioId,
      nome: nome,
      tipo: 'urbana',
      observacoes: '',
      actorId: supervisorId,
    );
    localidadeController.clear();
    await carregar();
  }

  Future<void> criarSetor() async {
    final localidade = localidadeSelecionada;
    if (localidade == null) return;
    final codigo = setorCodigoController.text.trim();
    final nome = setorNomeController.text.trim();
    if (codigo.isEmpty || nome.isEmpty) return;

    await setorRepo.criarOuAtualizar(
      municipioId: municipioId,
      localidadeId: localidade.sync.id,
      codigo: codigo,
      nome: nome,
      descricao: '',
      supervisorId: supervisorId,
    );
    setorCodigoController.clear();
    setorNomeController.clear();
    await carregar();
  }

  Future<void> criarQuarteirao() async {
    final localidade = localidadeSelecionada;
    final setor = setorSelecionado;
    if (localidade == null || setor == null) return;

    final codigo = quarteiraoCodigoController.text.trim();
    final ordem = int.tryParse(ordemController.text.trim());
    final imoveis = int.tryParse(imoveisController.text.trim()) ?? 0;
    if (codigo.isEmpty || ordem == null) return;

    await quarteiraoRepo.criar(
      setorId: setor.sync.id,
      municipioId: municipioId,
      localidadeId: localidade.sync.id,
      codigo: codigo,
      ordemExecucao: ordem,
      totalImoveisPrevistos: imoveis,
      centroLatitude: double.tryParse(latitudeController.text.trim()),
      centroLongitude: double.tryParse(longitudeController.text.trim()),
      actorId: supervisorId,
    );
    quarteiraoCodigoController.clear();
    ordemController.clear();
    imoveisController.clear();
    latitudeController.clear();
    longitudeController.clear();
    await carregar();
  }

  Future<void> atribuirSetor() async {
    final setor = setorSelecionado;
    final ace = aceSelecionado;
    if (setor == null || ace == null) return;

    await atribuicaoRepo.atribuir(
      setorId: setor.sync.id,
      aceId: ace.nome,
      supervisorId: supervisorId,
      observacoes: observacaoAtribuicaoController.text.trim(),
    );
    observacaoAtribuicaoController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Setor atribuido para ${ace.nome}.')),
    );
  }

  Future<void> reabrirQuarteirao(QuarteiraoOperacionalModel quarteirao) async {
    final controller = TextEditingController();
    final justificativa = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reabrir quarteirao'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Justificativa obrigatoria',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );

    if (justificativa == null || justificativa.isEmpty) return;
    await quarteiraoRepo.reabrir(
      quarteirao: quarteirao,
      actorId: supervisorId,
      justificativa: justificativa,
    );
    await carregar();
  }

  Widget campo(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Territorio operacional')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Localidades',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: campo(localidadeController, 'Nome da localidade')),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: criarLocalidade,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<LocalidadeModel>(
            initialValue: localidadeSelecionada,
            items: localidades
                .map((item) => DropdownMenuItem(value: item, child: Text(item.nome)))
                .toList(),
            onChanged: (value) async {
              setState(() {
                localidadeSelecionada = value;
                setorSelecionado = null;
              });
              await carregar();
            },
            decoration: const InputDecoration(
              labelText: 'Localidade selecionada',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Setores', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: campo(setorCodigoController, 'Codigo')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: campo(setorNomeController, 'Nome do setor')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: criarSetor,
            icon: const Icon(Icons.add_road),
            label: const Text('Criar setor'),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<SetorOperacionalModel>(
            initialValue: setorSelecionado,
            items: setores
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text('${item.codigo} - ${item.nome}'),
                    ))
                .toList(),
            onChanged: (value) async {
              setState(() => setorSelecionado = value);
              await carregar();
            },
            decoration: const InputDecoration(
              labelText: 'Setor selecionado',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Quarteiroes do setor', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: campo(quarteiraoCodigoController, 'Codigo')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: campo(
                  ordemController,
                  'Ordem',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          campo(
            imoveisController,
            'Imoveis previstos',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: campo(
                  latitudeController,
                  'Latitude central',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: campo(
                  longitudeController,
                  'Longitude central',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: criarQuarteirao,
            icon: const Icon(Icons.crop_square),
            label: const Text('Adicionar quarteirao ao setor'),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in quarteiroes)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(item.status),
                  child: Text('${item.ordemExecucao}'),
                ),
                title: Text(item.codigo),
                subtitle: Text(
                  '${item.status} - ${item.totalImoveisPrevistos} imoveis previstos',
                ),
                trailing: item.status == 'concluido'
                    ? IconButton(
                        tooltip: 'Reabrir',
                        icon: const Icon(Icons.lock_open),
                        onPressed: () => reabrirQuarteirao(item),
                      )
                    : null,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text('Atribuicao de setor', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<ACEProfileModel>(
            initialValue: aceSelecionado,
            items: perfis
                .map((item) => DropdownMenuItem(value: item, child: Text(item.nome)))
                .toList(),
            onChanged: (value) => setState(() => aceSelecionado = value),
            decoration: const InputDecoration(
              labelText: 'ACE responsavel',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          campo(observacaoAtribuicaoController, 'Observacoes da atribuicao'),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: atribuirSetor,
            icon: const Icon(Icons.assignment_ind),
            label: const Text('Atribuir setor ao ACE'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'concluido':
        return AppColors.emDia;
      case 'em_andamento':
        return AppColors.informativo;
      case 'pendente':
      case 'critico':
        return AppColors.atrasado;
      default:
        return AppColors.textMuted;
    }
  }
}

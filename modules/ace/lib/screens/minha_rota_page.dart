import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/territorio_models.dart';
import '../repositories/atribuicao_setor_repository.dart';
import '../repositories/progresso_quarteirao_repository.dart';
import '../repositories/quarteirao_repository.dart';
import '../repositories/setor_repository.dart';

class MinhaRotaPage extends StatefulWidget {
  final String? aceId;

  const MinhaRotaPage({super.key, this.aceId});

  @override
  State<MinhaRotaPage> createState() => _MinhaRotaPageState();
}

class _MinhaRotaPageState extends State<MinhaRotaPage> {
  final atribuicaoRepo = AtribuicaoSetorRepository();
  final setorRepo = SetorRepository();
  final quarteiraoRepo = QuarteiraoRepository();
  final progressoRepo = ProgressoQuarteiraoRepository();

  String aceId = '';
  List<AtribuicaoSetorModel> atribuicoes = [];
  SetorOperacionalModel? setor;
  List<QuarteiraoOperacionalModel> quarteiroes = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final config = await DatabaseHelper.instance.carregarConfiguracao();
    final agente = widget.aceId ?? config['agente'] ?? '';
    final listaAtribuicoes = await atribuicaoRepo.listarPorAce(agente);
    final setorAtual = listaAtribuicoes.isEmpty
        ? null
        : await setorRepo.buscarPorId(listaAtribuicoes.first.setorId);
    final listaQuarteiroes = setorAtual == null
        ? <QuarteiraoOperacionalModel>[]
        : await quarteiraoRepo.listarPorSetor(setorAtual.sync.id);

    if (!mounted) return;
    setState(() {
      aceId = agente;
      atribuicoes = listaAtribuicoes;
      setor = setorAtual;
      quarteiroes = listaQuarteiroes;
      carregando = false;
    });
  }

  QuarteiraoOperacionalModel? get proximo {
    for (final item in quarteiroes) {
      if (item.status != 'concluido') return item;
    }
    return null;
  }

  Future<String?> pedirJustificativa() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fora da ordem definida'),
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
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> iniciar(QuarteiraoOperacionalModel quarteirao) async {
    String? justificativa;
    if (proximo?.sync.id != quarteirao.sync.id) {
      justificativa = await pedirJustificativa();
      if (justificativa == null || justificativa.isEmpty) return;
    }

    await progressoRepo.iniciar(
      quarteirao: quarteirao,
      aceId: aceId,
      justificativa: justificativa,
    );
    await carregar();
  }

  Future<void> concluir(QuarteiraoOperacionalModel quarteirao) async {
    final controllerVisitados = TextEditingController(
      text: quarteirao.totalVisitados.toString(),
    );
    final controllerPendencias = TextEditingController(
      text: quarteirao.totalPendencias.toString(),
    );
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Concluir ${quarteirao.codigo}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controllerVisitados,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Imoveis visitados',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controllerPendencias,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pendencias',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    await progressoRepo.concluir(
      quarteirao: quarteirao,
      aceId: aceId,
      totalVisitados: int.tryParse(controllerVisitados.text.trim()) ?? 0,
      totalPendencias: int.tryParse(controllerPendencias.text.trim()) ?? 0,
    );
    await carregar();
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Minha rota')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.route, color: AppColors.primary),
              title: Text(setor == null ? 'Nenhum setor atribuido' : setor!.nome),
              subtitle: Text(
                setor == null
                    ? 'Peça ao supervisor para atribuir um setor.'
                    : 'ACE: $aceId - ${atribuicoes.length} atribuicao ativa',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (proximo != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.informativo.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Text(
                'Proximo quarteirao: ${proximo!.codigo}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          for (final item in quarteiroes)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(item.status),
                  foregroundColor: Colors.white,
                  child: Text('${item.ordemExecucao}'),
                ),
                title: Text(item.codigo),
                subtitle: Text(
                  '${item.status} - visitados ${item.totalVisitados} - pendencias ${item.totalPendencias}',
                ),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Iniciar',
                      onPressed: item.status == 'concluido'
                          ? null
                          : () => iniciar(item),
                      icon: const Icon(Icons.play_arrow),
                    ),
                    IconButton(
                      tooltip: 'Concluir',
                      onPressed: item.status == 'concluido'
                          ? null
                          : () => concluir(item),
                      icon: const Icon(Icons.check_circle),
                    ),
                  ],
                ),
              ),
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

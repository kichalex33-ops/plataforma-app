import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/pe_model.dart';
import '../services/sync_service.dart';
import '../utils/epidemiological_calendar.dart';
import '../utils/pe_status.dart';
import 'pe_detail_page.dart';
import 'pe_form_page.dart';

class PEPage extends StatefulWidget {
  const PEPage({super.key});

  @override
  State<PEPage> createState() => _PEPageState();
}

class _PEPageState extends State<PEPage> {
  final buscaController = TextEditingController();

  List<PEModel> pontos = [];
  String filtroStatus = 'Todos';

  @override
  void initState() {
    super.initState();
    carregarPEs();
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  Future<void> carregarPEs() async {
    final lista = await DatabaseHelper.instance.listarPEs();

    if (!mounted) return;

    setState(() {
      pontos = lista;
    });
  }

  Future<void> abrirCadastroPE() async {
    final salvou = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PEFormPage()),
    );

    if (salvou == true) {
      await carregarPEs();
    }
  }

  Future<void> abrirDetalhePE(PEModel pe) async {
    if (pe.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PEDetailPage(peId: pe.id!, nome: pe.nome, endereco: pe.endereco),
      ),
    );

    await carregarPEs();
  }

  Future<void> confirmarExclusao(PEModel pe) async {
    final justificativaController = TextEditingController();

    final justificativa = await showDialog<String>(
      context: context,
      builder: (context) {
        var tentouSalvar = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final texto = justificativaController.text.trim();
            final mostrarErro = tentouSalvar && texto.length < 5;

            return AlertDialog(
              title: const Text('Excluir PE'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informe a justificativa para excluir "${pe.nome}".\n\nAs visitas vinculadas tambem serao apagadas, mas a exclusao ficara registrada.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: justificativaController,
                    minLines: 3,
                    maxLines: 5,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Justificativa obrigatoria',
                      hintText:
                          'Ex.: PE desativado, duplicado, endereco incorreto...',
                      errorText: mostrarErro
                          ? 'Descreva melhor o motivo da exclusao.'
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (texto.length < 5) {
                      setDialogState(() => tentouSalvar = true);
                      return;
                    }

                    Navigator.pop(context, texto);
                  },
                  child: const Text(
                    'Excluir',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    justificativaController.dispose();

    if (justificativa != null && pe.id != null) {
      final config = await DatabaseHelper.instance.carregarConfiguracao();
      await DatabaseHelper.instance.excluirPEComJustificativa(
        pe: pe,
        justificativa: justificativa,
        agente: config['agente'] ?? 'ACE nao informado',
        municipio: config['municipio'] ?? 'Municipio nao informado',
      );

      unawaited(
        SyncService.configurado().then(
          (servico) => servico.sincronizarPendentes(),
        ),
      );

      await carregarPEs();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PE excluido com justificativa.')),
      );
    }
  }

  Future<void> confirmarExclusaoAntiga(PEModel pe) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir PE'),
          content: Text(
            'Tem certeza que deseja excluir "${pe.nome}"?\n\nAs visitas vinculadas também serão apagadas.',
          ),
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
        );
      },
    );

    if (confirmar == true && pe.id != null) {
      await DatabaseHelper.instance.excluirPE(pe.id!);
      await carregarPEs();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PE excluído com sucesso.')));
    }
  }

  Color corStatus(String status) {
    if (status == PEStatus.emDia) return AppColors.emDia;
    if (status == PEStatus.vencendo) return AppColors.vencendo;
    return AppColors.atrasado;
  }

  IconData iconeStatus(String status) {
    if (status == PEStatus.emDia) return Icons.check_circle;
    if (status == PEStatus.vencendo) return Icons.warning;
    return Icons.error;
  }

  int contarPorStatus(String status) {
    return pontos.where((pe) => PEStatus.calcular(pe) == status).length;
  }

  String textoUltimaVisita(PEModel pe) {
    if (pe.ultimaVisita == null || pe.ultimaVisita!.isEmpty) {
      return 'Última visita: nunca';
    }

    return 'Última visita: ${pe.ultimaVisita}';
  }

  List<PEModel> get pontosFiltrados {
    final busca = buscaController.text.trim().toLowerCase();

    return pontos.where((pe) {
      final status = PEStatus.calcular(pe);
      final correspondeAoStatus =
          filtroStatus == 'Todos' || filtroStatus == status;
      final correspondeABusca =
          busca.isEmpty ||
          pe.nome.toLowerCase().contains(busca) ||
          pe.endereco.toLowerCase().contains(busca) ||
          pe.tipo.toLowerCase().contains(busca);

      return correspondeAoStatus && correspondeABusca;
    }).toList();
  }

  Widget construirResumo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pontos Estratégicos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _ResumoItem(
                label: 'Total',
                valor: pontos.length.toString(),
                color: Colors.white,
              ),
              _ResumoItem(
                label: 'Em dia',
                valor: contarPorStatus(PEStatus.emDia).toString(),
                color: AppColors.emDia,
              ),
              _ResumoItem(
                label: 'Vencendo',
                valor: contarPorStatus(PEStatus.vencendo).toString(),
                color: AppColors.vencendo,
              ),
              _ResumoItem(
                label: 'Atrasados',
                valor: contarPorStatus(PEStatus.atrasado).toString(),
                color: AppColors.atrasado,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget construirFiltros() {
    const filtros = [
      'Todos',
      PEStatus.emDia,
      PEStatus.vencendo,
      PEStatus.atrasado,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: buscaController,
          decoration: const InputDecoration(
            hintText: 'Buscar PE, endereço ou tipo',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filtros.map((filtro) {
              final selecionado = filtroStatus == filtro;
              final cor = filtro == 'Todos'
                  ? AppColors.primary
                  : corStatus(filtro);

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(filtro),
                  selected: selecionado,
                  selectedColor: cor.withValues(alpha: 0.16),
                  checkmarkColor: cor,
                  labelStyle: TextStyle(
                    color: selecionado ? cor : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(color: cor.withValues(alpha: 0.35)),
                  onSelected: (_) {
                    setState(() {
                      filtroStatus = filtro;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget construirCardCiclo() {
    final cicloPE = EpidemiologicalCalendar.cicloPEAtual();
    if (cicloPE == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cicloPE.titulo} - ${cicloPE.semanas}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  cicloPE.periodo,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget construirCardPE(PEModel pe) {
    final status = PEStatus.calcular(pe);
    final cor = corStatus(status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border(left: BorderSide(color: cor, width: 5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => abrirDetalhePE(pe),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                    ),
                    child: Icon(Icons.location_city, color: cor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pe.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textStrong,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          pe.tipo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir PE',
                    onPressed: () => confirmarExclusao(pe),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.place, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pe.endereco,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _StatusBadge(
                    status: status,
                    color: cor,
                    icon: iconeStatus(status),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      textoUltimaVisita(pe),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget construirEstadoVazio(String texto, IconData icone) {
    return Padding(
      padding: const EdgeInsets.only(top: 72),
      child: Column(
        children: [
          Icon(icone, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = pontosFiltrados;

    return Scaffold(
      appBar: AppBar(title: const Text('Pontos Estratégicos')),
      body: RefreshIndicator(
        onRefresh: carregarPEs,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            construirResumo(),
            const SizedBox(height: AppSpacing.lg),
            construirFiltros(),
            const SizedBox(height: AppSpacing.md),
            construirCardCiclo(),
            const SizedBox(height: AppSpacing.lg),
            if (pontos.isEmpty)
              construirEstadoVazio(
                'Nenhum PE cadastrado.',
                Icons.add_location_alt,
              )
            else if (lista.isEmpty)
              construirEstadoVazio(
                'Nenhum PE encontrado para este filtro.',
                Icons.search_off,
              )
            else
              ...lista.map(construirCardPE),
            const SizedBox(height: 84),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: abrirCadastroPE,
        icon: const Icon(Icons.add),
        label: const Text('Novo PE'),
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _ResumoItem({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          children: [
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

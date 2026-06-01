import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/relatorio_pe_item_model.dart';
import '../utils/epidemiological_calendar.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  final buscaController = TextEditingController();

  List<RelatorioPEItemModel> itens = [];
  String filtro = 'Todas';
  String periodoSelecionado = 'Todos';
  int? cicloSelecionado;
  String aceSelecionado = 'Todos';
  String peSelecionado = 'Todos';

  @override
  void initState() {
    super.initState();
    carregarRelatorio();
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  Future<void> carregarRelatorio() async {
    final lista = await DatabaseHelper.instance.listarRelatorioPE();

    if (!mounted) return;

    setState(() {
      itens = lista;
    });
  }

  List<RelatorioPEItemModel> get itensFiltrados {
    final busca = buscaController.text.trim().toLowerCase();

    return itens.where((item) {
      final visita = item.visita;
      final dataVisita = converterData(visita.saidaEm);
      final combinaFiltro =
          filtro == 'Todas' ||
          (filtro == 'Foco positivo' && visita.focoPositivo) ||
          (filtro == 'Com foto' && visita.fotoPath.isNotEmpty);
      final combinaPeriodo = filtrarPorPeriodo(dataVisita);
      final combinaCiclo = filtrarPorCiclo(dataVisita);
      final combinaACE =
          aceSelecionado == 'Todos' || visita.agente.trim() == aceSelecionado;
      final combinaPE =
          peSelecionado == 'Todos' || item.peNome == peSelecionado;

      final combinaBusca =
          busca.isEmpty ||
          item.peNome.toLowerCase().contains(busca) ||
          item.peEndereco.toLowerCase().contains(busca) ||
          item.peTipo.toLowerCase().contains(busca) ||
          visita.agente.toLowerCase().contains(busca) ||
          visita.municipio.toLowerCase().contains(busca);

      return combinaFiltro &&
          combinaPeriodo &&
          combinaCiclo &&
          combinaACE &&
          combinaPE &&
          combinaBusca;
    }).toList();
  }

  List<String> get acesDisponiveis {
    final nomes =
        itens
            .map((item) => item.visita.agente.trim())
            .where((nome) => nome.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return ['Todos', ...nomes];
  }

  List<String> get pesDisponiveis {
    final nomes = itens.map((item) => item.peNome).toSet().toList()..sort();

    return ['Todos', ...nomes];
  }

  DateTime? converterData(String dataTexto) {
    try {
      final partes = dataTexto.split(' ');
      final data = partes[0].split('/');
      final hora = partes.length > 1 ? partes[1].split(':') : ['0', '0'];

      return DateTime(
        int.parse(data[2]),
        int.parse(data[1]),
        int.parse(data[0]),
        int.parse(hora[0]),
        int.parse(hora[1]),
      );
    } catch (_) {
      return null;
    }
  }

  bool filtrarPorPeriodo(DateTime? data) {
    if (periodoSelecionado == 'Todos') return true;
    if (data == null) return false;

    final agora = DateTime.now();

    if (periodoSelecionado == 'Últimos 7 dias') {
      return data.isAfter(agora.subtract(const Duration(days: 7)));
    }

    if (periodoSelecionado == 'Últimos 30 dias') {
      return data.isAfter(agora.subtract(const Duration(days: 30)));
    }

    if (periodoSelecionado == 'Ciclo PE atual') {
      final ciclo = EpidemiologicalCalendar.cicloPEAtual();
      return ciclo?.contem(data) ?? false;
    }

    return true;
  }

  bool filtrarPorCiclo(DateTime? data) {
    if (cicloSelecionado == null) return true;
    if (data == null) return false;

    PECycle? ciclo;
    for (final item in EpidemiologicalCalendar.ciclosPE2026) {
      if (item.numero == cicloSelecionado) {
        ciclo = item;
        break;
      }
    }

    return ciclo?.contem(data) ?? false;
  }

  int get totalTubitos {
    return itensFiltrados.fold(
      0,
      (total, item) => total + item.visita.quantidadeTubitos,
    );
  }

  int get totalFotos {
    return itensFiltrados
        .where((item) => item.visita.fotoPath.isNotEmpty)
        .length;
  }

  int get totalFocos {
    return itensFiltrados.where((item) => item.visita.focoPositivo).length;
  }

  int get totalComGPS {
    return itensFiltrados.where((item) {
      final visita = item.visita;
      return visita.saidaLatitude != null && visita.saidaLongitude != null;
    }).length;
  }

  int get totalComObservacao {
    return itensFiltrados
        .where((item) => item.visita.observacoes.trim().isNotEmpty)
        .length;
  }

  Map<String, _ResumoGrupo> agruparPorACE() {
    final grupos = <String, _ResumoGrupo>{};

    for (final item in itensFiltrados) {
      final nome = item.visita.agente.trim().isEmpty
          ? 'ACE não informado'
          : item.visita.agente.trim();
      grupos.putIfAbsent(nome, () => _ResumoGrupo(nome));
      grupos[nome]!.adicionar(item);
    }

    return grupos;
  }

  Map<String, _ResumoGrupo> agruparPorPE() {
    final grupos = <String, _ResumoGrupo>{};

    for (final item in itensFiltrados) {
      grupos.putIfAbsent(item.peNome, () => _ResumoGrupo(item.peNome));
      grupos[item.peNome]!.adicionar(item);
    }

    return grupos;
  }

  void abrirFoto(String fotoPath) {
    if (fotoPath.isEmpty || !File(fotoPath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto não encontrada no aparelho.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _FotoRelatorioPage(fotoPath)),
    );
  }

  Widget construirResumo() {
    final ciclo = EpidemiologicalCalendar.cicloPEAtual();

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
            'Relatório operacional PE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ciclo == null
                ? 'Período: $periodoSelecionado'
                : '${ciclo.titulo}: ${ciclo.periodo}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.05,
            children: [
              _ResumoNumero(
                titulo: 'Visitas',
                valor: itensFiltrados.length.toString(),
                icon: Icons.assignment_turned_in,
              ),
              _ResumoNumero(
                titulo: 'Focos',
                valor: totalFocos.toString(),
                icon: Icons.warning,
              ),
              _ResumoNumero(
                titulo: 'Tubitos',
                valor: totalTubitos.toString(),
                icon: Icons.science,
              ),
              _ResumoNumero(
                titulo: 'Fotos',
                valor: totalFotos.toString(),
                icon: Icons.photo_camera,
              ),
              _ResumoNumero(
                titulo: 'GPS',
                valor: totalComGPS.toString(),
                icon: Icons.my_location,
              ),
              _ResumoNumero(
                titulo: 'Obs.',
                valor: totalComObservacao.toString(),
                icon: Icons.notes,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget construirFiltros() {
    const filtros = ['Todas', 'Foco positivo', 'Com foto'];
    const periodos = [
      'Todos',
      'Ciclo PE atual',
      'Últimos 7 dias',
      'Últimos 30 dias',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: buscaController,
          decoration: const InputDecoration(
            hintText: 'Buscar por PE, endereço, tipo, ACE ou município',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: aceSelecionado,
                decoration: const InputDecoration(
                  labelText: 'ACE',
                  prefixIcon: Icon(Icons.person),
                ),
                items: acesDisponiveis.map((ace) {
                  return DropdownMenuItem(value: ace, child: Text(ace));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    aceSelecionado = value;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: cicloSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Ciclo PE',
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...EpidemiologicalCalendar.ciclosPE2026.map((ciclo) {
                    return DropdownMenuItem<int?>(
                      value: ciclo.numero,
                      child: Text(
                        '${ciclo.numero.toString().padLeft(2, '0')} - ${ciclo.periodo}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    cicloSelecionado = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: peSelecionado,
          decoration: const InputDecoration(
            labelText: 'Ponto Estrategico',
            prefixIcon: Icon(Icons.location_city),
          ),
          items: pesDisponiveis.map((pe) {
            return DropdownMenuItem(value: pe, child: Text(pe));
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              peSelecionado = value;
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: periodos.map((periodo) {
              final selecionado = periodoSelecionado == periodo;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(periodo),
                  selected: selecionado,
                  selectedColor: AppColors.primary.withValues(alpha: 0.16),
                  labelStyle: TextStyle(
                    color: selecionado
                        ? AppColors.primary
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) {
                    setState(() {
                      periodoSelecionado = periodo;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filtros.map((opcao) {
              final selecionado = filtro == opcao;
              final cor = opcao == 'Foco positivo'
                  ? AppColors.atrasado
                  : opcao == 'Com foto'
                  ? AppColors.primary
                  : AppColors.emDia;

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(opcao),
                  selected: selecionado,
                  selectedColor: cor.withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    color: selecionado ? cor : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) {
                    setState(() {
                      filtro = opcao;
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

  Widget construirResumoGrupos({
    required String titulo,
    required IconData icon,
    required Map<String, _ResumoGrupo> grupos,
  }) {
    final lista = grupos.values.toList()
      ..sort((a, b) => b.visitas.compareTo(a.visitas));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (lista.isEmpty)
              const Text(
                'Sem dados para os filtros atuais.',
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              ...lista.take(6).map((grupo) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          grupo.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _MiniBadge(texto: '${grupo.visitas} visitas'),
                      const SizedBox(width: 6),
                      _MiniBadge(texto: '${grupo.focos} focos'),
                      const SizedBox(width: 6),
                      _MiniBadge(texto: '${grupo.tubitos} tubitos'),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget construirItem(RelatorioPEItemModel item) {
    final visita = item.visita;
    final tubitos = visita.tubitos.isEmpty ? '-' : visita.tubitos.join(', ');
    final temFoto =
        visita.fotoPath.isNotEmpty && File(visita.fotoPath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border(
          left: BorderSide(
            color: visita.focoPositivo ? AppColors.atrasado : AppColors.emDia,
            width: 5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.peNome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      item.peEndereco,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (temFoto)
                IconButton(
                  tooltip: 'Ver foto',
                  onPressed: () => abrirFoto(visita.fotoPath),
                  icon: const Icon(
                    Icons.photo_camera,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ChipInfo(
                icon: Icons.category,
                texto: item.peTipo,
                color: AppColors.primary,
              ),
              _ChipInfo(
                icon: Icons.science,
                texto: visita.focoPositivo ? 'Foco positivo' : 'Sem foco',
                color: visita.focoPositivo
                    ? AppColors.atrasado
                    : AppColors.emDia,
              ),
              _ChipInfo(
                icon: temFoto ? Icons.photo_camera : Icons.no_photography,
                texto: temFoto ? 'Foto' : 'Sem foto',
                color: temFoto ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _LinhaRelatorio(
            icon: Icons.person,
            texto: visita.agente.isEmpty ? 'ACE não informado' : visita.agente,
          ),
          _LinhaRelatorio(
            icon: Icons.location_city,
            texto: visita.municipio.isEmpty
                ? 'Município não informado'
                : visita.municipio,
          ),
          _LinhaRelatorio(
            icon: Icons.login,
            texto: 'Entrada: ${visita.entradaEm}',
          ),
          _LinhaRelatorio(
            icon: Icons.logout,
            texto: 'Saída: ${visita.saidaEm}',
          ),
          _LinhaRelatorio(
            icon: Icons.assignment,
            texto: 'Situação: ${visita.situacao}',
          ),
          if (visita.focoPositivo) ...[
            _LinhaRelatorio(icon: Icons.numbers, texto: 'Tubitos: $tubitos'),
            _LinhaRelatorio(
              icon: Icons.calculate,
              texto: 'Quantidade: ${visita.quantidadeTubitos}',
            ),
          ],
          _LinhaRelatorio(
            icon: Icons.my_location,
            texto: visita.latitude == null || visita.longitude == null
                ? 'GPS pendente para próxima fase'
                : '${visita.latitude}, ${visita.longitude}',
          ),
          if (visita.observacoes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              visita.observacoes,
              style: const TextStyle(color: AppColors.textStrong),
            ),
          ],
        ],
      ),
    );
  }

  Widget construirQualidadeRegistros() {
    final total = itensFiltrados.length;
    final semFoto = total - totalFotos;
    final semGPS = total - totalComGPS;
    final comFoco = totalFocos;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Qualidade do registro',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _LinhaQualidade(
              titulo: 'Visitas com foto',
              valor: '$totalFotos de $total',
              cor: total == 0 || semFoto == 0
                  ? AppColors.emDia
                  : AppColors.vencendo,
            ),
            _LinhaQualidade(
              titulo: 'Visitas com GPS de saida',
              valor: '$totalComGPS de $total',
              cor: total == 0 || semGPS == 0
                  ? AppColors.emDia
                  : AppColors.vencendo,
            ),
            _LinhaQualidade(
              titulo: 'Focos positivos no filtro',
              valor: '$comFoco',
              cor: comFoco == 0 ? AppColors.emDia : AppColors.atrasado,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = itensFiltrados;

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios PE')),
      body: RefreshIndicator(
        onRefresh: carregarRelatorio,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            construirResumo(),
            const SizedBox(height: AppSpacing.lg),
            construirFiltros(),
            const SizedBox(height: AppSpacing.lg),
            construirResumoGrupos(
              titulo: 'Resumo por ACE',
              icon: Icons.person,
              grupos: agruparPorACE(),
            ),
            const SizedBox(height: AppSpacing.md),
            construirResumoGrupos(
              titulo: 'Resumo por PE',
              icon: Icons.location_city,
              grupos: agruparPorPE(),
            ),
            const SizedBox(height: AppSpacing.md),
            construirQualidadeRegistros(),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Visitas filtradas',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (lista.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 56),
                child: Center(
                  child: Text(
                    'Nenhuma visita encontrada.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                  ),
                ),
              )
            else
              ...lista.map(construirItem),
          ],
        ),
      ),
    );
  }
}

class _ResumoGrupo {
  final String nome;
  int visitas = 0;
  int focos = 0;
  int tubitos = 0;

  _ResumoGrupo(this.nome);

  void adicionar(RelatorioPEItemModel item) {
    visitas++;
    if (item.visita.focoPositivo) focos++;
    tubitos += item.visita.quantidadeTubitos;
  }
}

class _ResumoNumero extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icon;

  const _ResumoNumero({
    required this.titulo,
    required this.valor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String texto;

  const _MiniBadge({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LinhaQualidade extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color cor;

  const _LinhaQualidade({
    required this.titulo,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Text(
              valor,
              style: TextStyle(
                color: cor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color color;

  const _ChipInfo({
    required this.icon,
    required this.texto,
    required this.color,
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
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            texto,
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

class _LinhaRelatorio extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _LinhaRelatorio({required this.icon, required this.texto});

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

class _FotoRelatorioPage extends StatelessWidget {
  final String fotoPath;

  const _FotoRelatorioPage(this.fotoPath);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foto da visita')),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(fotoPath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

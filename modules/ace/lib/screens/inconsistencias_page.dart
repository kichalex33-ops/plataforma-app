import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';

class InconsistenciasPage extends StatefulWidget {
  const InconsistenciasPage({super.key});

  @override
  State<InconsistenciasPage> createState() => _InconsistenciasPageState();
}

class _InconsistenciasPageState extends State<InconsistenciasPage> {
  List<_Inconsistencia> itens = [];
  bool carregando = true;
  String filtro = 'Todas';

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final resultado = <_Inconsistencia>[];
    final db = DatabaseHelper.instance;
    final pes = await db.listarPEs();
    final relatorioPE = await db.listarRelatorioPE();
    final domiciliares = await db.listarVisitasDomiciliares();
    final resumoSync = await db.listarResumoSincronizacao();
    final errosSync = await db.listarErrosSincronizacao();

    for (final pe in pes) {
      if (pe.latitude == null || pe.longitude == null) {
        resultado.add(
          _Inconsistencia(
            modulo: 'PE',
            titulo: pe.nome,
            descricao: 'Ponto estrategico sem coordenada GPS cadastrada.',
            gravidade: _Gravidade.media,
            icone: Icons.location_off,
          ),
        );
      }
    }

    for (final item in relatorioPE) {
      final visita = item.visita;
      final fotoExiste =
          visita.fotoPath.isNotEmpty && File(visita.fotoPath).existsSync();

      if (!fotoExiste) {
        resultado.add(
          _Inconsistencia(
            modulo: 'Visita PE',
            titulo: item.peNome,
            descricao: 'Visita sem foto disponivel para relatorio.',
            gravidade: _Gravidade.alta,
            icone: Icons.no_photography,
          ),
        );
      }

      if (visita.saidaLatitude == null || visita.saidaLongitude == null) {
        resultado.add(
          _Inconsistencia(
            modulo: 'Visita PE',
            titulo: item.peNome,
            descricao: 'Visita sem GPS de saida registrado.',
            gravidade: _Gravidade.alta,
            icone: Icons.gps_off,
          ),
        );
      }

      if (visita.focoPositivo && visita.tubitos.isEmpty) {
        resultado.add(
          _Inconsistencia(
            modulo: 'Visita PE',
            titulo: item.peNome,
            descricao: 'Foco positivo sem numeracao de tubitos listada.',
            gravidade: _Gravidade.alta,
            icone: Icons.science_outlined,
          ),
        );
      }
    }

    for (final visita in domiciliares) {
      final endereco = '${visita.endereco}, ${visita.numero}';

      if (visita.rgQuarteiraoCodigo.isEmpty) {
        resultado.add(
          _Inconsistencia(
            modulo: 'Visita domiciliar',
            titulo: endereco,
            descricao: 'Visita domiciliar sem vinculo com quarteirao RG.',
            gravidade: _Gravidade.media,
            icone: Icons.grid_off,
          ),
        );
      }

      if (visita.saidaLatitude == 0 || visita.saidaLongitude == 0) {
        resultado.add(
          _Inconsistencia(
            modulo: 'Visita domiciliar',
            titulo: endereco,
            descricao: 'Visita domiciliar sem GPS de saida valido.',
            gravidade: _Gravidade.alta,
            icone: Icons.gps_off,
          ),
        );
      }

      if (visita.focoPositivo && visita.tubitos.isEmpty) {
        resultado.add(
          _Inconsistencia(
            modulo: 'Visita domiciliar',
            titulo: endereco,
            descricao: 'Foco positivo sem numeracao de tubitos listada.',
            gravidade: _Gravidade.alta,
            icone: Icons.science_outlined,
          ),
        );
      }
    }

    for (final item in resumoSync) {
      final pendentes = item['pendentes'] as int? ?? 0;
      if (pendentes > 0) {
        resultado.add(
          _Inconsistencia(
            modulo: 'Sincronizacao',
            titulo: item['modulo']?.toString() ?? 'Modulo',
            descricao: '$pendentes registro(s) aguardando envio ao servidor.',
            gravidade: _Gravidade.baixa,
            icone: Icons.cloud_upload_outlined,
          ),
        );
      }
    }

    for (final erro in errosSync) {
      resultado.add(
        _Inconsistencia(
          modulo: 'Erro de sincronizacao',
          titulo: '${erro['modulo']} #${erro['id']}',
          descricao: erro['erro']?.toString() ?? 'Erro nao informado.',
          gravidade: _Gravidade.alta,
          icone: Icons.sync_problem,
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      itens = resultado;
      carregando = false;
    });
  }

  List<_Inconsistencia> get itensFiltrados {
    if (filtro == 'Todas') return itens;
    return itens.where((item) => item.gravidade.nome == filtro).toList();
  }

  int contar(String nome) {
    if (nome == 'Todas') return itens.length;
    return itens.where((item) => item.gravidade.nome == nome).length;
  }

  Widget construirFiltros() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in ['Todas', 'Alta', 'Media', 'Baixa'])
          ChoiceChip(
            label: Text('$item (${contar(item)})'),
            selected: filtro == item,
            onSelected: (_) => setState(() => filtro = item),
          ),
      ],
    );
  }

  Widget construirResumo() {
    return Row(
      children: [
        Expanded(
          child: _ResumoInconsistenciaCard(
            titulo: 'Alta',
            valor: contar('Alta').toString(),
            cor: AppColors.atrasado,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ResumoInconsistenciaCard(
            titulo: 'Media',
            valor: contar('Media').toString(),
            cor: AppColors.vencendo,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ResumoInconsistenciaCard(
            titulo: 'Baixa',
            valor: contar('Baixa').toString(),
            cor: AppColors.informativo,
          ),
        ),
      ],
    );
  }

  Widget construirLista() {
    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final lista = itensFiltrados;

    if (lista.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Nenhuma inconsistencia encontrada para este filtro.'),
        ),
      );
    }

    return Column(
      children: lista.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border(left: BorderSide(color: item.gravidade.cor, width: 5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: item.gravidade.cor.withValues(alpha: 0.12),
                child: Icon(item.icone, color: item.gravidade.cor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.modulo,
                      style: TextStyle(
                        color: item.gravidade.cor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.titulo,
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.descricao,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inconsistencias')),
      body: RefreshIndicator(
        onRefresh: carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            construirResumo(),
            const SizedBox(height: AppSpacing.lg),
            construirFiltros(),
            const SizedBox(height: AppSpacing.lg),
            construirLista(),
          ],
        ),
      ),
    );
  }
}

class _Inconsistencia {
  final String modulo;
  final String titulo;
  final String descricao;
  final _Gravidade gravidade;
  final IconData icone;

  const _Inconsistencia({
    required this.modulo,
    required this.titulo,
    required this.descricao,
    required this.gravidade,
    required this.icone,
  });
}

enum _Gravidade {
  alta('Alta', AppColors.atrasado),
  media('Media', AppColors.vencendo),
  baixa('Baixa', AppColors.informativo);

  final String nome;
  final Color cor;

  const _Gravidade(this.nome, this.cor);
}

class _ResumoInconsistenciaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color cor;

  const _ResumoInconsistenciaCard({
    required this.titulo,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border(top: BorderSide(color: cor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            valor,
            style: TextStyle(
              color: cor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

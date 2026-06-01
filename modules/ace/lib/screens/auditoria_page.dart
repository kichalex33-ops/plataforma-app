import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/exclusao_log_model.dart';

class AuditoriaPage extends StatefulWidget {
  const AuditoriaPage({super.key});

  @override
  State<AuditoriaPage> createState() => _AuditoriaPageState();
}

class _AuditoriaPageState extends State<AuditoriaPage> {
  List<ExclusaoLogModel> exclusoes = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final lista = await DatabaseHelper.instance.listarExclusoesLog();

    if (!mounted) return;

    setState(() {
      exclusoes = lista;
      carregando = false;
    });
  }

  String formatarData(String valor) {
    final data = DateTime.tryParse(valor);
    if (data == null) return valor.isEmpty ? 'Data nao informada' : valor;

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano $hora:$minuto';
  }

  Widget construirResumo() {
    final pendentes = exclusoes.where((item) => item.sincronizado == 0).length;
    final enviadas = exclusoes.length - pendentes;

    return Row(
      children: [
        Expanded(
          child: _ResumoAuditoriaCard(
            titulo: 'Exclusoes',
            valor: exclusoes.length.toString(),
            cor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ResumoAuditoriaCard(
            titulo: 'Enviadas',
            valor: enviadas.toString(),
            cor: AppColors.emDia,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ResumoAuditoriaCard(
            titulo: 'Pendentes',
            valor: pendentes.toString(),
            cor: pendentes == 0 ? AppColors.textMuted : AppColors.vencendo,
          ),
        ),
      ],
    );
  }

  Widget construirLista() {
    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (exclusoes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Nenhuma exclusao registrada.'),
        ),
      );
    }

    return Column(
      children: exclusoes.map((item) {
        final sincronizado = item.sincronizado == 1;
        final temErro =
            item.erroSincronizacao != null &&
            item.erroSincronizacao!.trim().isNotEmpty;
        final corStatus = sincronizado
            ? AppColors.emDia
            : (temErro ? AppColors.atrasado : AppColors.vencendo);
        final textoStatus = sincronizado
            ? 'Sincronizada'
            : (temErro ? 'Erro no envio' : 'Pendente');

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border(left: BorderSide(color: corStatus, width: 5)),
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
                  CircleAvatar(
                    backgroundColor: AppColors.atrasado.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.atrasado,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.entidade} #${item.entidadeId}',
                          style: const TextStyle(
                            color: AppColors.textStrong,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          formatarData(item.dataHora),
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  _StatusAuditoriaChip(texto: textoStatus, cor: corStatus),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _LinhaAuditoria(icon: Icons.description, texto: item.descricao),
              _LinhaAuditoria(
                icon: Icons.person,
                texto: item.agente.isEmpty ? 'ACE nao informado' : item.agente,
              ),
              _LinhaAuditoria(
                icon: Icons.location_city,
                texto: item.municipio.isEmpty
                    ? 'Municipio nao informado'
                    : item.municipio,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Text(
                  item.justificativa,
                  style: const TextStyle(color: AppColors.textStrong),
                ),
              ),
              if (temErro) ...[
                const SizedBox(height: AppSpacing.sm),
                _LinhaAuditoria(
                  icon: Icons.sync_problem,
                  texto: item.erroSincronizacao!,
                  cor: AppColors.atrasado,
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
      appBar: AppBar(title: const Text('Auditoria')),
      body: RefreshIndicator(
        onRefresh: carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            construirResumo(),
            const SizedBox(height: AppSpacing.lg),
            construirLista(),
          ],
        ),
      ),
    );
  }
}

class _ResumoAuditoriaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color cor;

  const _ResumoAuditoriaCard({
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

class _StatusAuditoriaChip extends StatelessWidget {
  final String texto;
  final Color cor;

  const _StatusAuditoriaChip({required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LinhaAuditoria extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color cor;

  const _LinhaAuditoria({
    required this.icon,
    required this.texto,
    this.cor = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(texto, style: TextStyle(color: cor)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../auth/motorista_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../modules/transportes/models/viagem_model.dart';
import '../../modules/transportes/models/viagem_status.dart';
import '../../widgets/route_summary_panel.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import '../passageiros/passageiros_viagem_page.dart';
import 'models/evento_viagem_tipo.dart';
import 'viagem_execucao_controller.dart';

class ViagemDetalhePage extends StatefulWidget {
  final ViagemModel viagem;
  final MotoristaModel motorista;

  const ViagemDetalhePage({
    super.key,
    required this.viagem,
    required this.motorista,
  });

  @override
  State<ViagemDetalhePage> createState() => _ViagemDetalhePageState();
}

class _ViagemDetalhePageState extends State<ViagemDetalhePage> {
  late final ViagemExecucaoController controller;
  String? statusLocal;

  @override
  void initState() {
    super.initState();
    controller = ViagemExecucaoController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _formatarData(String valor) {
    final data = DateTime.tryParse(valor);
    if (data == null) return valor;

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _acao(String tipo) async {
    await controller.registrarAcao(
      viagem: widget.viagem,
      motorista: widget.motorista,
      tipo: tipo,
    );

    if (!mounted) return;
    setState(() => statusLocal = tipo);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento registrado localmente.')),
    );
  }

  void _abrirPassageiros() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PassageirosViagemPage(
          viagem: widget.viagem,
          motorista: widget.motorista,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viagem = widget.viagem;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da viagem')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          RouteSummaryPanel(
            origem: viagem.origem,
            destino: viagem.destino,
            horario: _formatarData(viagem.dataHoraSaida),
            finalidade: viagem.finalidade,
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(
            title: 'Dados operacionais',
            subtitle: 'Informacoes da viagem atribuida pelo painel.',
          ),
          _DetalheCard(
            icon: Icons.info_outline,
            label: 'Status',
            value: statusLocal ?? ViagemStatus.label(viagem.status),
            trailing: StatusBadge(
              label: statusLocal ?? ViagemStatus.label(viagem.status),
              status: statusLocal ?? viagem.status,
            ),
          ),
          _DetalheCard(
            icon: Icons.badge,
            label: 'Motorista logado',
            value: widget.motorista.nome,
          ),
          if (viagem.veiculoId?.isNotEmpty == true)
            _DetalheCard(
              icon: Icons.directions_bus,
              label: 'Veiculo',
              value: viagem.veiculoId!,
            ),
          if (viagem.observacoes?.isNotEmpty == true)
            _DetalheCard(
              icon: Icons.notes,
              label: 'Observacoes',
              value: viagem.observacoes!,
            ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(
            title: 'Execucao da viagem',
            subtitle: 'Acoes registram eventos locais offline-first.',
          ),
          _AcaoButton(
            icon: Icons.check_circle,
            label: 'Aceitar viagem',
            onPressed: () => _acao(EventoViagemTipo.viagemAceita),
          ),
          _AcaoButton(
            icon: Icons.play_arrow,
            label: 'Iniciar viagem',
            onPressed: () => _acao(EventoViagemTipo.viagemIniciada),
          ),
          _AcaoButton(
            icon: Icons.airline_seat_recline_normal,
            label: 'Ver passageiros',
            onPressed: _abrirPassageiros,
          ),
          _AcaoButton(
            icon: Icons.report,
            label: 'Registrar ocorrencia',
            onPressed: () => _acao(EventoViagemTipo.ocorrenciaRegistrada),
          ),
          _AcaoButton(
            icon: Icons.stop_circle,
            label: 'Encerrar viagem',
            onPressed: () => _acao(EventoViagemTipo.viagemEncerrada),
          ),
        ],
      ),
    );
  }
}

class _DetalheCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _DetalheCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        trailing: trailing,
      ),
    );
  }
}

class _AcaoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _AcaoButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

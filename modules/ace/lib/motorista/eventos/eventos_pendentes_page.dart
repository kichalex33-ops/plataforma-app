import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../sync/driver_sync_panel.dart';
import 'models/evento_operacional_model.dart';
import 'services/evento_operacional_service.dart';

class EventosPendentesPage extends StatefulWidget {
  const EventosPendentesPage({super.key});

  @override
  State<EventosPendentesPage> createState() => _EventosPendentesPageState();
}

class _EventosPendentesPageState extends State<EventosPendentesPage> {
  final service = EventoOperacionalService();
  bool carregando = true;
  List<EventoOperacionalModel> eventos = const [];
  String? erro;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    try {
      final resultado = await service.listarPendentes();
      if (!mounted) return;
      setState(() {
        eventos = resultado;
        carregando = false;
        erro = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        erro = error.toString();
        carregando = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos pendentes')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: DriverSyncPanel(),
          ),
          const Divider(height: 1),
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : erro != null
                ? Center(
                    child: Text(
                      erro!,
                      style: const TextStyle(color: AppColors.atrasado),
                    ),
                  )
                : eventos.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum evento pendente',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: carregar,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: eventos.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final evento = eventos[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.pending_actions,
                              color: AppColors.primary,
                            ),
                            title: Text(evento.tipo),
                            subtitle: Text(_formatarData(evento.createdAt)),
                            trailing: Chip(label: Text(evento.syncStatus)),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

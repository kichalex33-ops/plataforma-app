import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/sync_status_card.dart';
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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SyncStatusCard(
              online: true,
              title: 'Fila local de eventos',
              description:
                  'Eventos operacionais ficam salvos no aparelho ate a sincronizacao.',
              pending: eventos.length,
              child: const DriverSyncPanel(),
            ),
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
                ? const EmptyStateCard(
                    icon: Icons.cloud_done,
                    title: 'Nenhum evento pendente',
                    message: 'A fila local esta livre para sincronizacao.',
                  )
                : RefreshIndicator(
                    onRefresh: carregar,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        SectionHeader(
                          title: 'Eventos aguardando envio',
                          subtitle: '${eventos.length} evento(s) na fila.',
                        ),
                        ...List.generate(eventos.length, (index) {
                          final evento = eventos[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Card(
                              child: ListTile(
                                leading: const Icon(Icons.pending_actions),
                                title: Text(evento.tipo),
                                subtitle: Text(
                                  [
                                    _formatarData(evento.createdAt),
                                    'Viagem: ${evento.viagemId}',
                                  ].join('\n'),
                                ),
                                trailing: StatusBadge(
                                  label: evento.syncStatus,
                                  status: evento.syncStatus,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

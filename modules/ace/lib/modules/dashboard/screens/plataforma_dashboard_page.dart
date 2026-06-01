import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/operational_metric_card.dart';

class PlataformaDashboardPage extends StatefulWidget {
  final bool embed;

  const PlataformaDashboardPage({super.key, this.embed = false});

  @override
  State<PlataformaDashboardPage> createState() =>
      _PlataformaDashboardPageState();
}

class _PlataformaDashboardPageState extends State<PlataformaDashboardPage> {
  late final PlataformaDashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = PlataformaDashboardController()..carregar();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embed
          ? null
          : AppBar(title: const Text('Painel logistico')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.carregando || controller.indicadores == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = controller.indicadores!;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              OperationalMetricCard(
                icon: Icons.route,
                title: 'Viagens programadas',
                value: data.viagens.toString(),
                color: AppColors.primary,
              ),
              OperationalMetricCard(
                icon: Icons.people,
                title: 'Pacientes atendidos',
                value: data.pacientes.toString(),
                color: AppColors.informativo,
              ),
              OperationalMetricCard(
                icon: Icons.airline_seat_recline_normal,
                title: 'Passageiros em agenda',
                value: data.passageiros.toString(),
                color: AppColors.emDia,
              ),
              OperationalMetricCard(
                icon: Icons.directions_bus,
                title: 'Veiculos cadastrados',
                value: data.veiculos.toString(),
                color: AppColors.atrasado,
              ),
              OperationalMetricCard(
                icon: Icons.cloud_upload,
                title: 'Pendencias de sync',
                value: data.pendenciasSync.toString(),
                color: AppColors.relatorios,
              ),
            ],
          );
        },
      ),
    );
  }
}

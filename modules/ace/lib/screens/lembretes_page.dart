import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../utils/epidemiological_calendar.dart';

class LembretesPage extends StatelessWidget {
  const LembretesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lembretes = EpidemiologicalCalendar.lembretesLiraaLia2026;
    final ciclos = EpidemiologicalCalendar.ciclosMunicipiosInfestados2026;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lembretes Operacionais'),
        backgroundColor: AppColors.informativo,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text(
            'LIRAa/LIA 2026',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Orientações operacionais conforme informe DVAS/CEVS de 12/02/2026.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...lembretes.map(_LembreteCard.new),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Ciclos - municípios infestados',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Seis ciclos no ano, de dois em dois meses.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...ciclos.map(_CicloCard.new),
        ],
      ),
    );
  }
}

class _LembreteCard extends StatelessWidget {
  final OperationalReminder lembrete;

  const _LembreteCard(this.lembrete);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.informativo,
          child: Icon(Icons.notifications_active, color: Colors.white),
        ),
        title: Text(
          lembrete.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${lembrete.periodo}\n${lembrete.descricao}'),
        isThreeLine: true,
      ),
    );
  }
}

class _CicloCard extends StatelessWidget {
  final GeneralCycle ciclo;

  const _CicloCard(this.ciclo);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            ciclo.numero.toString().padLeft(2, '0'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('${ciclo.titulo} - ${ciclo.semanas}'),
        subtitle: Text(ciclo.periodo),
      ),
    );
  }
}

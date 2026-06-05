import 'package:flutter/material.dart';

import '../../core/auth/app_auth_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/audit/pages/audit_history_page.dart';
import '../../features/indicators/pages/local_indicators_page.dart';
import '../../features/reports/pages/local_reports_page.dart';

class OperadorLogisticaPage extends StatelessWidget {
  final AppUser user;

  const OperadorLogisticaPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Operacao Logistica')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            user.nomeCompleto,
            style: const TextStyle(
              color: AppColors.navyDeep,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${user.funcao} | ${user.municipio}',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Card(
            child: ListTile(
              leading: Icon(Icons.assignment_turned_in),
              title: Text('Painel operacional permitido'),
              subtitle: Text(
                'Area preparada para controlador logistico no app. O painel web oficial permanece em projeto separado.',
              ),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.security),
              title: Text('Permissoes aplicadas'),
              subtitle: Text('Acesso concedido pelo cadastro do painel web.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.insights),
              title: const Text('Indicadores locais'),
              subtitle: const Text(
                'Resumo offline calculado com dados salvos no aparelho.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocalIndicatorsPage(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Relatorios locais'),
              subtitle: const Text(
                'Resumo operacional offline preparado para exportacao futura.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocalReportsPage()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Auditoria local'),
              subtitle: const Text(
                'Historico local de eventos importantes do app.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuditHistoryPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

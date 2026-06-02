import 'package:flutter/material.dart';

import '../../core/auth/app_auth_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class OperadorLogisticaPage extends StatelessWidget {
  final AppUser user;

  const OperadorLogisticaPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Operação Logística')),
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
                'Área preparada para controlador logístico no app. O painel web oficial permanece em projeto separado.',
              ),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.security),
              title: Text('Permissões aplicadas'),
              subtitle: Text('Acesso concedido pelo cadastro do painel web.'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/auth/app_auth_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AcsModulePage extends StatelessWidget {
  final AppUser user;

  const AcsModulePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ACS')),
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
              leading: Icon(Icons.health_and_safety),
              title: Text('Módulo ACS'),
              subtitle: Text(
                'Entrada preparada para usuários ACS autorizados pelo painel.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

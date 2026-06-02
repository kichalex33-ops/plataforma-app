import 'package:flutter/material.dart';

import '../core/session/app_access_mode.dart';
import '../core/theme/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../modules/ace/ace_module_page.dart';
import '../modules/logistica/logistica_module_page.dart';

class ModuleSelectorPage extends StatelessWidget {
  final AppAccessMode accessMode;

  const ModuleSelectorPage({
    super.key,
    this.accessMode = AppAccessMode.normal,
  });

  bool get isGodMode => accessMode == AppAccessMode.godMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Andrade Gestão em Saúde'),
        actions: [
          if (isGodMode)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: const Text(
                    'God Mode',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Image.asset(
            AppAssets.logoHorizontal,
            height: 94,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Selecione o módulo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Acesse as áreas operacionais da plataforma municipal.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ModuleCard(
            title: 'Logística',
            subtitle: 'Transporte sanitário, viagens, frota e check-in.',
            status: 'Demonstração operacional',
            icon: Icons.local_shipping,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogisticaModulePage()),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _ModuleCard(
            title: 'ACE',
            subtitle: 'Rotinas territoriais preservadas para demonstração.',
            status: 'Demonstração territorial',
            icon: Icons.home_work,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AceModulePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.22)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: AppColors.gold, size: 31),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.navyDeep,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}

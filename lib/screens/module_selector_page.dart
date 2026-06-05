import 'package:flutter/material.dart';

import '../core/auth/app_auth_models.dart';
import '../core/session/app_access_mode.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../main.dart';
import '../modules/logistica/logistica_module_page.dart';
import '../modules/logistica/operador_logistica_page.dart';
import 'appearance_settings_page.dart';

class ModuleSelectorPage extends StatelessWidget {
  final AppAccessMode accessMode;
  final AppUser? user;

  const ModuleSelectorPage({
    super.key,
    this.accessMode = AppAccessMode.normal,
    this.user,
  });

  bool get isGodMode => accessMode == AppAccessMode.godMode;

  List<AppModule> get _visibleModules {
    if (isGodMode) return const [AppModule.logistica];
    return user?.modulosPermitidos
            .where((module) => module == AppModule.logistica)
            .toList(growable: false) ??
        const [];
  }

  @override
  Widget build(BuildContext context) {
    final modules = _visibleModules;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plataforma Logistica'),
        actions: [
          IconButton(
            tooltip: 'Aparencia',
            onPressed: () {
              final scope = AppThemeScope.of(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppearanceSettingsPage(
                    themeMode: scope.themeMode,
                    onChanged: scope.onThemeModeChanged,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.contrast),
          ),
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
          const _Header(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isGodMode ? 'Acesso total' : 'Modulo disponivel',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Esta estrutura permanece preparada para liberar outros modulos autorizados pelo painel quando forem incluidos no app.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final module in modules) ...[
            _ModuleCard(
              title: _title(module),
              subtitle: _subtitle(module),
              status: isGodMode ? 'Acesso total' : 'Autorizado pelo painel',
              icon: _icon(module),
              onTap: () => _openModule(context, module),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (modules.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Usuario sem permissao ativa. Procure o operador responsavel.',
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _title(AppModule module) {
    return switch (module) {
      AppModule.logistica => 'Logistica',
    };
  }

  String _subtitle(AppModule module) {
    return switch (module) {
      AppModule.logistica => 'Transporte sanitario, viagens, frota e check-in.',
    };
  }

  IconData _icon(AppModule module) {
    return switch (module) {
      AppModule.logistica => Icons.local_shipping,
    };
  }

  void _openModule(BuildContext context, AppModule module) {
    final currentUser = user;
    switch (module) {
      case AppModule.logistica:
        if (!isGodMode && currentUser?.perfil == AppProfile.operadorLogistica) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OperadorLogisticaPage(user: currentUser!),
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LogisticaModulePage(user: currentUser),
          ),
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.navyDeep,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_shipping, color: Colors.white, size: 38),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Plataforma Logistica',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
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

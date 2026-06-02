import 'package:flutter/material.dart';

import '../core/auth/app_auth_models.dart';
import '../core/session/app_access_mode.dart';
import '../core/theme/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../main.dart';
import '../modules/ace/ace_module_page.dart';
import '../modules/acs/acs_module_page.dart';
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
    if (isGodMode) return AppModule.values;
    return user?.modulosPermitidos ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final modules = _visibleModules;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Andrade Gestão em Saúde'),
        actions: [
          IconButton(
            tooltip: 'Aparência',
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
          Image.asset(
            AppAssets.logoHorizontal,
            height: 94,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isGodMode ? 'Acesso total' : 'Selecione o módulo',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isGodMode
                ? 'Todos os módulos e ferramentas avançadas liberados.'
                : 'Apenas módulos autorizados pelo painel web aparecem aqui.',
            style: const TextStyle(color: AppColors.textMuted),
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
                  'Usuário sem permissão ativa. Procure o operador responsável.',
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _title(AppModule module) {
    return switch (module) {
      AppModule.logistica => 'Logística',
      AppModule.ace => 'ACE',
      AppModule.acs => 'ACS',
    };
  }

  String _subtitle(AppModule module) {
    return switch (module) {
      AppModule.logistica =>
        'Transporte sanitário, viagens, frota e check-in.',
      AppModule.ace => 'Rotinas territoriais preservadas para demonstração.',
      AppModule.acs => 'Atenção comunitária e visitas domiciliares.',
    };
  }

  IconData _icon(AppModule module) {
    return switch (module) {
      AppModule.logistica => Icons.local_shipping,
      AppModule.ace => Icons.home_work,
      AppModule.acs => Icons.health_and_safety,
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
      case AppModule.ace:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AceModulePage()),
        );
      case AppModule.acs:
        if (currentUser == null && !isGodMode) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AcsModulePage(
              user: currentUser ??
                  AppUser(
                    id: 'god-mode-acs',
                    nomeCompleto: 'GOD MODE',
                    login: 'GODMODE',
                    municipio: 'Todos',
                    funcao: 'Acesso total',
                    perfil: AppProfile.administrador,
                    permissoes: const {'all': true},
                    modulosPermitidos: AppModule.values,
                    ativo: true,
                    primeiroAcesso: false,
                  ),
            ),
          ),
        );
    }
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

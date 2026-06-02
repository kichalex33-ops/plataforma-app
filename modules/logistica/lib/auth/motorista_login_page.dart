import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../services/theme_mode_service.dart';
import 'motorista_model.dart';

typedef MotoristaOnEntrar =
    void Function(BuildContext context, MotoristaModel motorista);

class MotoristaLoginPage extends StatelessWidget {
  final MotoristaOnEntrar onEntrar;
  final ThemeModeService? themeModeService;

  const MotoristaLoginPage({
    super.key,
    required this.onEntrar,
    this.themeModeService,
    Object? session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              AppInfo.nome,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Acesso liberado pelo login institucional da plataforma.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login operacional removido',
                      style: TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Nome, município, função e permissões agora vêm do cadastro feito no painel web.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            if (themeModeService != null) ...[
              const SizedBox(height: AppSpacing.md),
              _ThemeModeSelector(service: themeModeService!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeModeService service;

  const _ThemeModeSelector({required this.service});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        return OutlinedButton.icon(
          onPressed: () => _mostrarOpcoes(context),
          icon: Icon(
            service.themeMode == ThemeMode.dark
                ? Icons.dark_mode
                : Icons.light_mode,
          ),
          label: Text('Tema: ${service.label}'),
        );
      },
    );
  }

  Future<void> _mostrarOpcoes(BuildContext context) async {
    final mode = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOptionTile(
              icon: Icons.light_mode,
              title: const Text('Modo claro'),
              selected: service.themeMode == ThemeMode.light,
              onTap: () => Navigator.pop(context, ThemeMode.light),
            ),
            _ThemeOptionTile(
              icon: Icons.dark_mode,
              title: const Text('Modo escuro'),
              selected: service.themeMode == ThemeMode.dark,
              onTap: () => Navigator.pop(context, ThemeMode.dark),
            ),
            _ThemeOptionTile(
              icon: Icons.settings_suggest,
              title: const Text('Usar configuração do sistema'),
              selected: service.themeMode == ThemeMode.system,
              onTap: () => Navigator.pop(context, ThemeMode.system),
            ),
          ],
        ),
      ),
    );

    if (mode != null) {
      await service.alterar(mode);
    }
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final Widget title;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: title,
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}

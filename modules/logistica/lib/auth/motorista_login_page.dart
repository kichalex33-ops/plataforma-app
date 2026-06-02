import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../services/theme_mode_service.dart';
import 'motorista_model.dart';
import 'motorista_session.dart';

typedef MotoristaOnEntrar =
    void Function(BuildContext context, MotoristaModel motorista);

class MotoristaLoginPage extends StatefulWidget {
  final MotoristaOnEntrar onEntrar;
  final MotoristaSession session;
  final ThemeModeService? themeModeService;

  MotoristaLoginPage({
    super.key,
    required this.onEntrar,
    this.themeModeService,
    MotoristaSession? session,
  }) : session = session ?? MotoristaSession();

  @override
  State<MotoristaLoginPage> createState() => _MotoristaLoginPageState();
}

class _MotoristaLoginPageState extends State<MotoristaLoginPage> {
  final nomeController = TextEditingController();
  final municipioController = TextEditingController();
  final senhaController = TextEditingController();
  bool ocultarSenha = true;
  bool carregando = true;
  bool entrando = false;

  @override
  void initState() {
    super.initState();
    carregarSessao();
  }

  Future<void> carregarSessao() async {
    final motorista = await widget.session.carregar();
    if (!mounted) return;

    if (motorista != null) {
      nomeController.text = motorista.nome;
      municipioController.text = motorista.municipio;
    }

    setState(() => carregando = false);
  }

  @override
  void dispose() {
    nomeController.dispose();
    municipioController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    if (entrando) return;

    final nome = nomeController.text.trim();
    final municipio = municipioController.text.trim();
    final senha = senhaController.text.trim();

    if (nome.isEmpty || municipio.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe motorista, município e senha.')),
      );
      return;
    }

    setState(() => entrando = true);

    try {
      final motorista = MotoristaModel(
        id: nome.toLowerCase().replaceAll(RegExp(r'\s+'), '-'),
        nome: nome,
        municipio: municipio,
      );
      await widget.session.salvar(motorista);

      if (!mounted) return;
      widget.onEntrar(context, motorista);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao entrar: $error')));
    } finally {
      if (mounted) setState(() => entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              'App institucional do motorista',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Acesso operacional',
                      style: TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Entre com os dados do motorista para acessar viagens e eventos offline.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: nomeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Motorista',
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: municipioController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Município',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: senhaController,
                      obscureText: ocultarSenha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => ocultarSenha = !ocultarSenha);
                          },
                          icon: Icon(
                            ocultarSenha
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => entrar(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: entrando ? null : entrar,
                      icon: const Icon(Icons.login),
                      label: Text(entrando ? 'Entrando...' : 'Entrar'),
                    ),
                    if (widget.themeModeService != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ThemeModeSelector(service: widget.themeModeService!),
                    ],
                  ],
                ),
              ),
            ),
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
              title: const Text('Usar configuracao do sistema'),
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

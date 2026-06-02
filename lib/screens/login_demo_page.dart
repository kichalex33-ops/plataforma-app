import 'package:flutter/material.dart';

import '../core/god_mode/god_mode_auth_service.dart';
import '../core/session/app_access_mode.dart';
import '../core/theme/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import 'god_mode_activation_screen.dart';
import 'module_selector_page.dart';

class LoginDemoPage extends StatefulWidget {
  const LoginDemoPage({super.key});

  @override
  State<LoginDemoPage> createState() => _LoginDemoPageState();
}

class _LoginDemoPageState extends State<LoginDemoPage> {
  static const _logisticaUsers = {'Alexk', 'Barbara', 'Gilyan'};
  static const _defaultUserPassword = '1234';

  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  final _godModeAuthService = GodModeAuthService();
  bool _ocultarSenha = true;
  bool _usarBiometria = false;

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final login = _loginController.text.trim();
    final senha = _senhaController.text.trim();

    if (_isLogisticaUser(login, senha)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ModuleSelectorPage(accessMode: AppAccessMode.normal),
        ),
      );
      return;
    }

    if (login.toUpperCase() == GodModeAuthService.godModeLogin) {
      final result = await _godModeAuthService.validateGodModeAccess(
        login: login,
        password: senha,
        requireBiometrics: _usarBiometria,
      );
      if (!mounted) return;
      if (!result.allowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Acesso negado.')),
        );
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GodModeActivationScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário ou senha inválidos.')),
    );
  }

  bool _isLogisticaUser(String login, String senha) {
    return _logisticaUsers.contains(login) && senha == _defaultUserPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, AppColors.navyDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      AppAssets.logoHorizontal,
                      width: 290,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Card(
                      elevation: 10,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        side: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.38),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Entrar na demo unificada',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: AppColors.navyDeep,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Andrade Gestão em Saúde',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextField(
                              controller: _loginController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Login',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _senhaController,
                              obscureText: _ocultarSenha,
                              onSubmitted: (_) => _entrar(),
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _ocultarSenha = !_ocultarSenha,
                                  ),
                                  icon: Icon(
                                    _ocultarSenha
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _usarBiometria,
                              onChanged: (value) => setState(
                                () => _usarBiometria = value ?? false,
                              ),
                              title: const Text('Entrar usando biometria'),
                              subtitle: const Text(
                                'Disponível para GOD MODE quando o aparelho permitir.',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FilledButton.icon(
                              onPressed: _entrar,
                              icon: const Icon(Icons.login),
                              label: const Text('Entrar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Logística: Alexk, Barbara ou Gilyan / 1234',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'GOD MODE: GODMODE / app2026',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

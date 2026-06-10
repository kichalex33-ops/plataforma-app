import 'package:flutter/material.dart';

import 'dart:async';

import '../core/auth/access_router.dart';
import '../core/auth/app_auth_models.dart';
import '../core/auth/auth_api_service.dart';
import '../core/auth/device_security_auth_service.dart';
import '../core/auth/panel_auth_service.dart';
import '../core/audit/models/audit_event_type.dart';
import '../core/sync/providers/sync_providers.dart';
import '../core/god_mode/god_mode_auth_service.dart';
import '../core/session/app_access_mode.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../main.dart';
import '../modules/logistica/logistica_module_page.dart';
import '../modules/logistica/operador_logistica_page.dart';
import 'alterar_senha_screen.dart';
import 'appearance_settings_page.dart';
import 'god_mode_activation_screen.dart';
import 'module_selector_page.dart';

class LoginDemoPage extends StatefulWidget {
  const LoginDemoPage({super.key});

  @override
  State<LoginDemoPage> createState() => _LoginDemoPageState();
}

class _LoginDemoPageState extends State<LoginDemoPage> {
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  final _panelAuthService = PanelAuthService();
  final _godModeAuthService = GodModeAuthService();
  final _deviceSecurityService = DeviceSecurityAuthService();
  bool _ocultarSenha = true;
  bool _usarBiometria = false;
  bool _entrando = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      auditAgentProvider.record(
        type: AuditEventType.appOpened,
        description: 'App aberto na tela de login.',
        origin: 'app',
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_entrando) return;
    final login = _loginController.text.trim();
    final senha = _senhaController.text.trim();

    if (_usarBiometria && login.isEmpty && senha.isEmpty) {
      await _entrarComBiometria();
      return;
    }

    if (login.isEmpty || senha.isEmpty) {
      _mostrarMensagem('Informe login e senha.');
      return;
    }

    setState(() => _entrando = true);
    try {
      if (login.toUpperCase() == GodModeAuthService.godModeLogin) {
        await _entrarGodMode(login, senha);
        return;
      }

      final AuthResult result;
      try {
        result = await _panelAuthService.authenticate(
          login: login,
          senha: senha,
        );
      } on AuthApiException catch (error) {
        if (!mounted) return;
        _mostrarMensagem(error.message);
        return;
      } catch (_) {
        if (!mounted) return;
        _mostrarMensagem('Nao foi possivel conectar ao painel.');
        return;
      }
      if (!mounted) return;
      if (!result.allowed || result.user == null) {
        _mostrarMensagem(result.message ?? 'Acesso negado.');
        return;
      }

      var user = result.user!;
      user = await _oferecerAlteracaoSenha(user) ?? user;
      await _oferecerBiometria(user);
      if (!mounted) return;
      await auditAgentProvider.record(
        type: AuditEventType.login,
        description: 'Login autorizado para ${user.login}.',
        origin: 'login',
        entityType: 'usuario',
        entityId: user.id,
        metadata: {'login': user.login, 'perfil': user.perfil.name},
      );
      _rotearUsuario(user);
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  Future<void> _entrarGodMode(String login, String senha) async {
    final result = await _godModeAuthService.validateGodModeAccess(
      login: login,
      password: senha,
      requireBiometrics: false,
    );
    if (!mounted) return;
    if (!result.allowed) {
      _mostrarMensagem(result.message ?? 'Acesso GOD MODE negado.');
      return;
    }
    await auditAgentProvider.record(
      type: AuditEventType.login,
      description: 'GOD MODE autorizado.',
      origin: 'god_mode',
      metadata: {'login': login},
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GodModeActivationScreen()),
    );
  }

  Future<void> _entrarComBiometria() async {
    setState(() => _entrando = true);
    try {
      final login = await _deviceSecurityService.unlockLinkedUser();
      if (!mounted) return;
      if (login == null) {
        _mostrarMensagem(
          'Faça primeiro login com senha para ativar a segurança do aparelho.',
        );
        return;
      }
      final user = await _panelAuthService.userByLogin(login);
      if (!mounted) return;
      if (user == null || !user.temPermissaoAtiva) {
        _mostrarMensagem(PanelAuthService.permissionDeniedMessage);
        return;
      }
      await auditAgentProvider.record(
        type: AuditEventType.login,
        description: 'Login por biometria autorizado para ${user.login}.',
        origin: 'biometria',
        entityType: 'usuario',
        entityId: user.id,
        metadata: {'login': user.login, 'perfil': user.perfil.name},
      );
      _rotearUsuario(user);
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  Future<AppUser?> _oferecerAlteracaoSenha(AppUser user) async {
    if (!user.primeiroAcesso) return null;
    final alterar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Senha inicial'),
        content: const Text(
          'Sua senha foi gerada no painel. Deseja criar uma senha pessoal agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Depois'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Alterar agora'),
          ),
        ],
      ),
    );
    if (alterar != true || !mounted) return null;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AlterarSenhaScreen(user: user, authService: _panelAuthService),
      ),
    );
    if (changed == true) {
      return _panelAuthService.userByLogin(user.login);
    }
    return null;
  }

  Future<void> _oferecerBiometria(AppUser user) async {
    if (await _deviceSecurityService.hasLinkedUser()) return;
    if (!mounted) return;
    final ativar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Segurança do aparelho'),
        content: const Text(
          'Deseja liberar os próximos acessos com digital, face, PIN, padrão ou senha do aparelho?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ativar'),
          ),
        ],
      ),
    );
    if (ativar == true) {
      final linked = await _deviceSecurityService.linkAuthenticatedUser(
        user.login,
      );
      if (!mounted) return;
      _mostrarMensagem(
        linked
            ? 'Segurança do aparelho ativada.'
            : 'Não foi possível ativar a segurança do aparelho.',
      );
    }
  }

  void _rotearUsuario(AppUser user) {
    final destination = AccessRouter.resolve(user);
    switch (destination) {
      case AccessDestination.logisticaMotorista:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LogisticaModulePage(user: user, onSair: _voltarAoLogin),
          ),
        );
      case AccessDestination.operadorLogistica:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OperadorLogisticaPage(user: user)),
        );
      case AccessDestination.moduleSelector:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ModuleSelectorPage(
              accessMode: AppAccessMode.normal,
              user: user,
            ),
          ),
        );
      case AccessDestination.denied:
        _mostrarMensagem(PanelAuthService.permissionDeniedMessage);
    }
  }

  void _voltarAoLogin() {
    unawaited(
      auditAgentProvider.record(
        type: AuditEventType.logout,
        description: 'Usuario retornou para a tela de login.',
        origin: 'app',
      ),
    );
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginDemoPage()),
      (_) => false,
    );
  }

  void _mostrarMensagem(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
          child: Stack(
            children: [
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  tooltip: 'Aparência',
                  color: Colors.white,
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
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: Colors.white,
                            size: 54,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Plataforma Logistica',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
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
                                  'Entrar na plataforma',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.navyDeep,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                const Text(
                                  'Operacao logistica municipal',
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
                                    'Disponível após o primeiro login válido.',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                FilledButton.icon(
                                  onPressed: _entrando ? null : _entrar,
                                  icon: const Icon(Icons.login),
                                  label: Text(
                                    _entrando ? 'Entrando...' : 'Entrar',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Acesso liberado pelo painel web conforme perfil e permissões.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

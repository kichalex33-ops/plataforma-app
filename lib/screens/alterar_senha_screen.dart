import 'package:flutter/material.dart';

import '../core/auth/app_auth_models.dart';
import '../core/auth/panel_auth_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class AlterarSenhaScreen extends StatefulWidget {
  final AppUser user;
  final PanelAuthService authService;

  const AlterarSenhaScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      await widget.authService.alterarSenha(
        login: widget.user.login,
        senhaAtual: _senhaAtualController.text,
        novaSenha: _novaSenhaController.text,
        confirmarNovaSenha: _confirmarSenhaController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AuthValidationException catch (error) {
      setState(() => _erro = error.message);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Alterar senha')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            widget.user.nomeCompleto,
            style: const TextStyle(
              color: AppColors.navyDeep,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Crie uma senha pessoal. A senha antiga será invalidada.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _senhaAtualController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Senha atual',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _novaSenhaController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nova senha',
              helperText: 'Mínimo 6 caracteres, letras e números.',
              prefixIcon: Icon(Icons.password),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _confirmarSenhaController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar nova senha',
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
          ),
          if (_erro != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_erro!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: _salvando ? null : _salvar,
            icon: const Icon(Icons.save),
            label: Text(_salvando ? 'Salvando...' : 'Salvar nova senha'),
          ),
        ],
      ),
    );
  }
}

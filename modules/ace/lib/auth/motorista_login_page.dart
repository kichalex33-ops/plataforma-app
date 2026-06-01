import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'motorista_model.dart';
import 'motorista_session.dart';

typedef MotoristaOnEntrar =
    void Function(BuildContext context, MotoristaModel motorista);

class MotoristaLoginPage extends StatefulWidget {
  final MotoristaOnEntrar onEntrar;
  final MotoristaSession session;

  MotoristaLoginPage({
    super.key,
    required this.onEntrar,
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
        const SnackBar(content: Text('Informe motorista, municipio e senha.')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao entrar: $error')),
      );
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            const Icon(
              Icons.local_shipping,
              size: 62,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              AppInfo.nome,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'App do motorista',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: nomeController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Motorista',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: municipioController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Municipio',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: senhaController,
              obscureText: ocultarSenha,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => ocultarSenha = !ocultarSenha);
                  },
                  icon: Icon(
                    ocultarSenha ? Icons.visibility : Icons.visibility_off,
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
          ],
        ),
      ),
    );
  }
}

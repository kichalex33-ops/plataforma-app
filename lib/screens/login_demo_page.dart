import 'package:flutter/material.dart';

import 'module_selector_page.dart';

class LoginDemoPage extends StatefulWidget {
  const LoginDemoPage({super.key});

  @override
  State<LoginDemoPage> createState() => _LoginDemoPageState();
}

class _LoginDemoPageState extends State<LoginDemoPage> {
  static const _navy = Color(0xFF2C3E50);
  static const _navyDark = Color(0xFF1A252F);
  static const _gold = Color(0xFFC9A96E);

  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _ocultarSenha = true;

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _entrar() {
    final login = _loginController.text.trim();
    final senha = _senhaController.text.trim();

    if (login == 'Alex' && senha == '1234') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ModuleSelectorPage()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario ou senha invalidos.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_navy, _navyDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: _gold, width: 2),
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: _gold,
                        size: 46,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Andrade',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gestao em Saude',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 34),
                    Card(
                      elevation: 8,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Entrar na demo unificada',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                              ),
                            ),
                            const SizedBox(height: 18),
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
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _entrar,
                              child: const Text('Entrar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Demo local: Alex / 1234',
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

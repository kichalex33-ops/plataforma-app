import 'package:flutter/material.dart';

import '../core/session/app_access_mode.dart';
import 'module_selector_page.dart';

class GodModeDashboard extends StatefulWidget {
  final AppAccessMode accessMode;

  const GodModeDashboard({super.key, required this.accessMode});

  @override
  State<GodModeDashboard> createState() => _GodModeDashboardState();
}

class _GodModeDashboardState extends State<GodModeDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accessMode != AppAccessMode.godMode) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Acesso negado',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('GOD MODE ATIVO'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF160000),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF0000)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acesso total validado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Todas as entradas deste modo passam por validação antes da animação.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ModuleSelectorPage(
                    accessMode: AppAccessMode.godMode,
                  ),
                ),
              ),
              icon: const Icon(Icons.dashboard),
              label: const Text('Abrir módulos'),
            ),
          ],
        ),
      ),
    );
  }
}

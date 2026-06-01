import 'package:flutter/material.dart';

import '../modules/ace/ace_module_page.dart';
import '../modules/logistica/logistica_module_page.dart';

class ModuleSelectorPage extends StatelessWidget {
  const ModuleSelectorPage({super.key});

  static const _navy = Color(0xFF2C3E50);
  static const _gold = Color(0xFFC9A96E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Andrade Gestão em Saúde')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Selecione o módulo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'A demo abre cada app preservando o visual e os fluxos originais.',
            style: TextStyle(color: Color(0xFF6C757D)),
          ),
          const SizedBox(height: 22),
          _ModuleCard(
            title: 'Logística',
            subtitle: 'Abre o módulo LogiSaúde preservado.',
            icon: Icons.local_shipping,
            color: _gold,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogisticaModulePage()),
              );
            },
          ),
          const SizedBox(height: 14),
          _ModuleCard(
            title: 'ACE',
            subtitle: 'Abre as telas territoriais preservadas.',
            icon: Icons.home_work,
            color: _navy,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AceModulePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF6C757D)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

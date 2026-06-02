import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SidebarMenu extends StatelessWidget {
  final double width;

  const SidebarMenu({super.key, this.width = 264});

  static const items = [
    (Icons.dashboard_rounded, 'Dashboard', true),
    (Icons.route_rounded, 'Viagens', false),
    (Icons.map_rounded, 'Mapa / Rastreamento', false),
    (Icons.person_pin_circle_rounded, 'Motoristas', false),
    (Icons.directions_car_rounded, 'Veículos', false),
    (Icons.people_alt_rounded, 'Pacientes / Solicitações', false),
    (Icons.warning_amber_rounded, 'Alertas', false),
    (Icons.assessment_rounded, 'Relatórios', false),
    (Icons.sync_rounded, 'Sincronização', false),
    (Icons.settings_rounded, 'Configurações', false),
    (Icons.manage_search_rounded, 'Auditoria / Logs', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: AppColors.primaryDark,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          child: Column(
            children: [
              const _Brand(),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MenuItem(
                      icon: item.$1,
                      label: item.$2,
                      selected: item.$3,
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alexandre',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Supervisor',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.local_shipping_rounded,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Logística',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {},
        hoverColor: AppColors.primary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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

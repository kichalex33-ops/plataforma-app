import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TopFilterBar extends StatelessWidget {
  final bool compact;
  final DateTime? atualizadoEm;

  const TopFilterBar({super.key, required this.compact, this.atualizadoEm});

  @override
  Widget build(BuildContext context) {
    final filters = [
      const _FilterBox(label: 'Município', value: 'Santa Maria'),
      const _FilterBox(
        label: 'Período',
        value: 'Maio/2026',
        icon: Icons.calendar_today_rounded,
      ),
      const _FilterBox(label: 'Status', value: 'Todos'),
      SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_alt_rounded, size: 18),
          label: const Text('Filtros'),
        ),
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 28,
        vertical: compact ? 16 : 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EFEA))),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard Executivo', style: _titleStyle),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: filters),
              ],
            )
          : Row(
              children: [
                const Expanded(
                  child: Text('Dashboard Executivo', style: _titleStyle),
                ),
                ...filters.map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: child,
                  ),
                ),
                const SizedBox(width: 18),
                const Badge(
                  label: Text('3'),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 18),
                const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alexandre',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Supervisor',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
    );
  }
}

class _FilterBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _FilterBox({
    required this.label,
    required this.value,
    this.icon = Icons.expand_more_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDE7E1)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: AppColors.textStrong, size: 17),
        ],
      ),
    );
  }
}

const _titleStyle = TextStyle(
  color: Colors.black,
  fontSize: 25,
  fontWeight: FontWeight.w900,
);

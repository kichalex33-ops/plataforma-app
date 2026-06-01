import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/status_badge.dart';
import '../../transportes/models/viagem_model.dart';
import 'dashboard_section_card.dart';

class RecentTripsCard extends StatelessWidget {
  final List<ViagemModel> viagens;

  const RecentTripsCard({super.key, required this.viagens});

  @override
  Widget build(BuildContext context) {
    final recentes = viagens.take(5).toList();
    return DashboardSectionCard(
      title: 'Últimas Viagens',
      trailing: const Text(
        'Ver todas',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      child: recentes.isEmpty
          ? const Text(
              'Nenhuma viagem registrada ainda.',
              style: TextStyle(color: AppColors.textMuted),
            )
          : Column(
              children: recentes
                  .map(
                    (viagem) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(
                              Icons.route_rounded,
                              size: 17,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${_shortId(viagem.sync.id)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${viagem.origem} → ${viagem.destino}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(label: viagem.status),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  String _shortId(String value) {
    if (value.length <= 8) return value;
    return value.substring(0, 8);
  }
}

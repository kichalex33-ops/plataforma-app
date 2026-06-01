import 'package:flutter/material.dart';

class TrackingLegend extends StatelessWidget {
  const TrackingLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4ECE7)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Legenda', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 10),
          _LegendItem('Em rota / Normal', Color(0xFF168039)),
          _LegendItem('Atenção', Color(0xFFFBC02D)),
          _LegendItem('Atraso', Color(0xFFFB8C00)),
          _LegendItem('Parado / Crítico', Color(0xFFE53935)),
          _LegendItem('Offline', Color(0xFF9AA3AA)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

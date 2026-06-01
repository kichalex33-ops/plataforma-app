import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CommandCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const CommandCard({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: onPressed == null
              ? AppColors.textMuted
              : AppColors.primary,
          side: BorderSide(
            color: onPressed == null
                ? const Color(0xFFE3E8E5)
                : const Color(0xFFD5E8DE),
          ),
          minimumSize: const Size.fromHeight(39),
          backgroundColor: onPressed == null
              ? const Color(0xFFF5F7F6)
              : Colors.white,
        ),
      ),
    );
  }
}

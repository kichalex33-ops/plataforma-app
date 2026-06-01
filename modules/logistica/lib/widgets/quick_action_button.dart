import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

class QuickActionButton extends StatelessWidget {
  final String texto;
  final IconData icone;
  final Color cor;
  final VoidCallback onPressed;

  const QuickActionButton({
    super.key,
    required this.texto,
    required this.icone,
    required this.cor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icone, size: 18),
          label: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: cor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
          ),
        ),
      ),
    );
  }
}

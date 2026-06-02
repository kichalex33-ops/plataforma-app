import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  static const title = TextStyle(
    color: AppColors.textStrong,
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );

  static const subtitle = TextStyle(
    color: AppColors.textMuted,
    fontSize: 14,
    height: 1.35,
  );

  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
}

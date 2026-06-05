import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'sidebar_menu.dart';
import 'top_filter_bar.dart';

class WebShell extends StatelessWidget {
  final Widget child;
  final DateTime? atualizadoEm;

  const WebShell({super.key, required this.child, this.atualizadoEm});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1080;
        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: desktop ? null : const Drawer(child: SidebarMenu(width: 282)),
          body: Row(
            children: [
              if (desktop) const SidebarMenu(),
              Expanded(
                child: Column(
                  children: [
                    TopFilterBar(
                      compact: constraints.maxWidth < 980,
                      atualizadoEm: atualizadoEm,
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

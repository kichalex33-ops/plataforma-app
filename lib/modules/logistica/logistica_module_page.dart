import 'package:flutter/material.dart';
import 'package:logisaude_driver/database/database_platform.dart' as log_db;
import 'package:logisaude_driver/main.dart' as log_app;
import 'package:logisaude_driver/services/theme_mode_service.dart' as log_theme;

class LogisticaModulePage extends StatefulWidget {
  const LogisticaModulePage({super.key});

  @override
  State<LogisticaModulePage> createState() => _LogisticaModulePageState();
}

class _LogisticaModulePageState extends State<LogisticaModulePage> {
  late final Future<log_theme.ThemeModeService> _bootstrap = _inicializar();

  Future<log_theme.ThemeModeService> _inicializar() async {
    await log_db.configurarBancoPorPlataforma();
    return log_theme.ThemeModeService.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<log_theme.ThemeModeService>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Logística')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erro ao abrir Logística: ${snapshot.error}'),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return log_app.LogiSaudeDriverApp(
          themeModeService: snapshot.data,
          mostrarLogin: false,
        );
      },
    );
  }
}

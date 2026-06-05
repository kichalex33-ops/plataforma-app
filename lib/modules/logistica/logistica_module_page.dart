import 'package:flutter/material.dart';
import 'package:plataforma_logistica_driver/auth/motorista_model.dart'
    as log_auth;
import 'package:plataforma_logistica_driver/database/database_platform.dart'
    as log_db;
import 'package:plataforma_logistica_driver/main.dart' as log_app;
import 'package:plataforma_logistica_driver/services/theme_mode_service.dart'
    as log_theme;

import '../../core/auth/app_auth_models.dart';

class LogisticaModulePage extends StatefulWidget {
  final AppUser? user;
  final VoidCallback? onSair;

  const LogisticaModulePage({super.key, this.user, this.onSair});

  @override
  State<LogisticaModulePage> createState() => _LogisticaModulePageState();
}

class _LogisticaModulePageState extends State<LogisticaModulePage> {
  late final Future<log_theme.ThemeModeService> _bootstrap = _inicializar();

  Future<log_theme.ThemeModeService> _inicializar() async {
    await log_db.configurarBancoPorPlataforma();
    return log_theme.ThemeModeService.carregar();
  }

  log_auth.MotoristaModel? _motoristaFromUser(AppUser? user) {
    if (user == null) return null;
    return log_auth.MotoristaModel(
      id: user.id,
      nome: user.nomeCompleto,
      municipio: user.municipio,
    );
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

        return log_app.PlataformaLogisticaDriverApp(
          themeModeService: snapshot.data,
          mostrarLogin: false,
          motorista: _motoristaFromUser(widget.user),
          onSair: widget.onSair,
        );
      },
    );
  }
}

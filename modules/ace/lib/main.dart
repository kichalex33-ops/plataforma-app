import 'package:flutter/material.dart';

import 'auth/motorista_login_page.dart';
import 'core/app_info.dart';
import 'core/theme/app_theme.dart';
import 'database/database_platform.dart';
import 'motorista/home/motorista_home_page.dart';
import 'services/theme_mode_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurarBancoPorPlataforma();
  final themeModeService = await ThemeModeService.carregar();
  runApp(LogiSaudeDriverApp(themeModeService: themeModeService));
}

class LogiSaudeDriverApp extends StatelessWidget {
  final ThemeModeService? themeModeService;
  final bool mostrarLogin;

  const LogiSaudeDriverApp({
    super.key,
    this.themeModeService,
    this.mostrarLogin = true,
  });

  @override
  Widget build(BuildContext context) {
    final service = themeModeService ?? ThemeModeService(ThemeMode.system);

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        return MaterialApp(
          title: AppInfo.nome,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: service.themeMode,
          home: mostrarLogin
              ? MotoristaLoginPage(
                  onEntrar: (loginContext, motorista) {
                    Navigator.pushReplacement(
                      loginContext,
                      MaterialPageRoute(
                        builder: (_) => MotoristaHomePage(
                          motorista: motorista,
                          themeModeService: service,
                        ),
                      ),
                    );
                  },
                )
              : MotoristaHomePage(themeModeService: service),
        );
      },
    );
  }
}

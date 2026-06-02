import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/app_intro_screen.dart';
import 'screens/login_demo_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AndradeDemoUnificadaApp());
}

class AndradeDemoUnificadaApp extends StatefulWidget {
  final bool showIntro;

  const AndradeDemoUnificadaApp({super.key, this.showIntro = true});

  @override
  State<AndradeDemoUnificadaApp> createState() =>
      _AndradeDemoUnificadaAppState();
}

class _AndradeDemoUnificadaAppState extends State<AndradeDemoUnificadaApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      themeMode: _themeMode,
      onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      child: MaterialApp(
        title: 'Andrade Gestão em Saúde',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        home: widget.showIntro ? const AppIntroScreen() : const LoginDemoPage(),
      ),
    );
  }
}

class AppThemeScope extends InheritedWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const AppThemeScope({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required super.child,
  });

  static AppThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope não encontrado.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}

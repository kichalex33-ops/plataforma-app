import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/login_demo_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AndradeDemoUnificadaApp());
}

class AndradeDemoUnificadaApp extends StatelessWidget {
  const AndradeDemoUnificadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Andrade Gestão em Saúde',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginDemoPage(),
    );
  }
}

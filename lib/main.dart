import 'package:flutter/material.dart';

import 'screens/login_demo_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AndradeDemoUnificadaApp());
}

class AndradeDemoUnificadaApp extends StatelessWidget {
  const AndradeDemoUnificadaApp({super.key});

  static const _navy = Color(0xFF2C3E50);
  static const _gold = Color(0xFFC9A96E);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Andrade Gestão em Saúde',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _gold,
          primary: _gold,
          secondary: _navy,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD8DEE6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _gold, width: 1.6),
          ),
        ),
      ),
      home: const LoginDemoPage(),
    );
  }
}

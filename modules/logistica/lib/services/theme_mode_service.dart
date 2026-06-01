import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class ThemeModeService extends ChangeNotifier {
  static const _configKey = 'theme_mode';

  ThemeMode _themeMode;

  ThemeModeService(this._themeMode);

  ThemeMode get themeMode => _themeMode;

  String get label {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Automatico';
    }
  }

  static Future<ThemeModeService> carregar() async {
    if (kIsWeb) {
      return ThemeModeService(ThemeMode.system);
    }

    final valor = await DatabaseHelper.instance.carregarValorConfiguracao(
      _configKey,
    );

    return ThemeModeService(_fromString(valor));
  }

  Future<void> alterar(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    if (kIsWeb) return;

    await DatabaseHelper.instance.salvarValorConfiguracao(
      _configKey,
      _toString(mode),
    );
  }

  static ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

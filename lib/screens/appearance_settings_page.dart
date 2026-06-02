import 'package:flutter/material.dart';

class AppearanceSettingsPage extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  const AppearanceSettingsPage({
    super.key,
    required this.themeMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aparência')),
      body: ListView(
        children: [
          _ThemeModeTile(
            title: 'Modo claro',
            value: ThemeMode.light,
            selectedValue: themeMode,
            onChanged: onChanged,
          ),
          _ThemeModeTile(
            title: 'Modo escuro',
            value: ThemeMode.dark,
            selectedValue: themeMode,
            onChanged: onChanged,
          ),
          _ThemeModeTile(
            title: 'Usar tema do sistema',
            value: ThemeMode.system,
            selectedValue: themeMode,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final String title;
  final ThemeMode value;
  final ThemeMode selectedValue;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeTile({
    required this.title,
    required this.value,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return ListTile(
      title: Text(title),
      trailing: selected ? const Icon(Icons.check_circle) : null,
      selected: selected,
      onTap: () => onChanged(value),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:logisaude_driver/core/app_info.dart';
import 'package:logisaude_driver/main.dart';

void main() {
  testWidgets('mostra home do motorista sem gestao administrativa', (
    WidgetTester tester,
  ) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await tester.pumpWidget(const LogiSaudeDriverApp(mostrarLogin: false));

    expect(find.text(AppInfo.nome), findsWidgets);
    expect(find.text('Motorista logado'), findsOneWidget);
    expect(find.text('Municipio local'), findsWidgets);
    expect(find.text('Viagem atual'), findsOneWidget);
    expect(find.text('Proximas viagens'), findsOneWidget);
    expect(find.text('Sincronizacao'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('Testar conexao'),
      120,
      scrollable: scrollable,
    );
    expect(find.text('Testar conexao'), findsOneWidget);
    expect(find.text('Sincronizar agora'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ver minhas viagens'),
      120,
      scrollable: scrollable,
    );
    expect(find.text('Ver minhas viagens'), findsOneWidget);
    expect(find.text('Continuar viagem'), findsOneWidget);

    expect(find.text('Painel'), findsNothing);
    expect(find.text('Auditoria'), findsNothing);
    expect(find.text('Pacientes'), findsNothing);
    expect(find.text('Veiculos'), findsNothing);
    expect(find.text('Motoristas'), findsNothing);
  });
}

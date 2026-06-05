import 'package:flutter_test/flutter_test.dart';

import 'package:plataforma_logistica/main.dart';

void main() {
  testWidgets('abre tela de login da Plataforma Logistica', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PlataformaLogisticaApp(showIntro: false));

    expect(find.text('Plataforma Logistica'), findsOneWidget);
    expect(find.text('Entrar na plataforma'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar usando biometria'), findsOneWidget);
  });
}

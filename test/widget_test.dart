import 'package:flutter_test/flutter_test.dart';

import 'package:andrade_demo_unificada/main.dart';

void main() {
  testWidgets('abre tela de login institucional', (WidgetTester tester) async {
    await tester.pumpWidget(const AndradeDemoUnificadaApp(showIntro: false));

    expect(find.text('Andrade Gestão em Saúde'), findsOneWidget);
    expect(find.text('Entrar na plataforma'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar usando biometria'), findsOneWidget);
  });
}

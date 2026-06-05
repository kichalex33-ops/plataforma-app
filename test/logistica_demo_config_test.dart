import 'package:flutter_test/flutter_test.dart';
import 'package:plataforma_logistica_driver/core/logistica/logistica_demo_config.dart';

void main() {
  test('seed de homologação fica desligado por padrão', () {
    expect(LogisticaDemoConfig.demoSeedEnabled, isFalse);
  });
}

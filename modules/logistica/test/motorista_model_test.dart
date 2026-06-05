import 'package:flutter_test/flutter_test.dart';

import 'package:plataforma_logistica_driver/auth/motorista_model.dart';

void main() {
  test('serializa motorista autenticado localmente', () {
    const motorista = MotoristaModel(
      id: 'motorista-local',
      nome: 'Roberto Lima',
      municipio: 'Montenegro',
    );

    expect(motorista.toMap(), {
      'id': 'motorista-local',
      'nome': 'Roberto Lima',
      'municipio': 'Montenegro',
    });
  });
}

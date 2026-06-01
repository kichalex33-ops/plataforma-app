import 'package:flutter_test/flutter_test.dart';

import 'package:logisaude_driver/motorista/passageiros/models/passageiro_operacao.dart';

void main() {
  test('expoe tipos de operacao de passageiro', () {
    expect(PassageiroOperacao.todos, [
      PassageiroOperacao.embarqueConfirmado,
      PassageiroOperacao.chegadaConfirmada,
      PassageiroOperacao.passageiroAusente,
      PassageiroOperacao.observacaoRegistrada,
    ]);
  });
}

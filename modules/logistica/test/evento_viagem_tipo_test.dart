import 'package:flutter_test/flutter_test.dart';

import 'package:logisaude_driver/motorista/viagem_atual/models/evento_viagem_tipo.dart';

void main() {
  test('expoe os tipos iniciais de evento operacional da viagem', () {
    expect(EventoViagemTipo.todos, [
      EventoViagemTipo.viagemAceita,
      EventoViagemTipo.checklistSaidaConfirmado,
      EventoViagemTipo.viagemIniciada,
      EventoViagemTipo.embarqueConfirmado,
      EventoViagemTipo.passageiroAusente,
      EventoViagemTipo.chegadaConfirmada,
      EventoViagemTipo.ocorrenciaRegistrada,
      EventoViagemTipo.localizacaoEnviada,
      EventoViagemTipo.viagemEncerrada,
    ]);
  });
}

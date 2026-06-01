import 'package:flutter_test/flutter_test.dart';

import 'package:controle_ace/motorista/eventos/models/evento_operacional_model.dart';

void main() {
  test('serializa evento operacional offline-first', () {
    const evento = EventoOperacionalModel(
      id: 'evento-1',
      viagemId: 'viagem-1',
      motoristaId: 'motorista-1',
      municipioId: 'municipio-1',
      tipo: EventoOperacionalTipo.viagemIniciada,
      payloadJson: '{"ok":true}',
      latitude: -29.1,
      longitude: -51.1,
      createdAt: '2026-05-28T10:00:00.000',
    );

    expect(evento.toMap(), {
      'id': 'evento-1',
      'viagem_id': 'viagem-1',
      'motorista_id': 'motorista-1',
      'municipio_id': 'municipio-1',
      'tipo': 'viagem_iniciada',
      'payload_json': '{"ok":true}',
      'latitude': -29.1,
      'longitude': -51.1,
      'created_at': '2026-05-28T10:00:00.000',
      'sync_status': 'pending',
    });
  });

  test('expoe tipos de eventos operacionais do motorista', () {
    expect(EventoOperacionalTipo.todos, contains('sync_executado'));
    expect(EventoOperacionalTipo.todos, contains('viagem_encerrada'));
  });
}

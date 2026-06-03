import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logisaude_driver/core/api/driver_api_client.dart';

void main() {
  test('consome contratos da fase 7 do app motorista', () async {
    final requests = <String>[];
    final client = DriverApiClient(
      client: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        final body = request.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(request.body) as Map<String, dynamic>;

        if (request.url.path == '/api/driver/login') {
          expect(body['identificador'], 'mot-001');
          return _json({
            'ok': true,
            'data': {
              'motorista': {'id': 'mot-001', 'nome': 'Joao'},
              'sessao': {'token': 'abc'},
            },
          });
        }
        if (request.url.path == '/api/driver/trips') {
          return _json({
            'ok': true,
            'data': {
              'viagens': [
                {'id': 'VIA-1', 'passageiros': []},
              ],
            },
          });
        }
        if (request.url.path == '/api/driver/notices') {
          return _json({
            'ok': true,
            'data': {
              'avisos': [
                {'titulo': 'Piloto'},
              ],
            },
          });
        }
        return _json({'ok': true, 'data': {}}, statusCode: 201);
      }),
    );

    final login = await client.loginMotorista(
      identificador: 'mot-001',
      senha: 'OPteste 01',
      lembrar: true,
    );
    final viagens = await client.buscarViagensDoMotorista('mot-001');
    final avisos = await client.buscarAvisosCentral();
    final checklist = await client.enviarChecklistPreViagem(
      viagemId: 'VIA-1',
      motoristaId: 'mot-001',
      itens: const {
        'documentacao': true,
        'pneus': true,
        'combustivel': true,
        'iluminacao': true,
        'freios': true,
        'limpeza': true,
      },
    );
    final km = await client.registrarKmInicial(
      viagemId: 'VIA-1',
      motoristaId: 'mot-001',
      kmSaida: 1000,
      latitude: -29.54,
      longitude: -51.48,
    );
    final fluxo = await client.enviarFluxoViagem(
      viagemId: 'VIA-1',
      action: 'confirmar-saida',
      motoristaId: 'mot-001',
    );
    final finalizacao = await client.finalizarViagem(
      viagemId: 'VIA-1',
      motoristaId: 'mot-001',
      kmFinal: 1048,
    );
    final panico = await client.acionarPanico(
      viagemId: 'VIA-1',
      motoristaId: 'mot-001',
      latitude: -29.54,
      longitude: -51.48,
    );
    final comprovante = await client.enviarComprovanteConsulta(
      viagemId: 'VIA-1',
      passageiroId: 'pas-001',
      arquivoNome: 'consulta.jpg',
    );

    expect(login?['motorista']['id'], 'mot-001');
    expect(viagens.single['id'], 'VIA-1');
    expect(avisos.single['titulo'], 'Piloto');
    expect(checklist, isTrue);
    expect(km, isTrue);
    expect(fluxo, isTrue);
    expect(finalizacao, isTrue);
    expect(panico, isTrue);
    expect(comprovante, isTrue);
    expect(requests, contains('POST /api/driver/login'));
    expect(requests, contains('POST /api/driver/trips/VIA-1/checklist'));
    expect(requests, contains('POST /api/driver/panic'));
  });
}

http.Response _json(Map<String, dynamic> body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

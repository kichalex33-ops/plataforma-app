import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plataforma_logistica_driver/core/api/driver_api_client.dart';

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
        if (request.url.path == '/api/viagens') {
          return _json({
            'ok': true,
            'data': {
              'viagens': [
                {'id': 'VIA-GERAL-1'},
              ],
            },
          });
        }
        if (request.url.path == '/api/motoristas') {
          return _json({
            'ok': true,
            'data': {
              'items': [
                {'id': 'mot-001'},
              ],
            },
          });
        }
        if (request.url.path == '/api/veiculos') {
          return _json({
            'ok': true,
            'data': {
              'items': [
                {'id': 'vei-001'},
              ],
            },
          });
        }
        if (request.url.path == '/api/pacientes') {
          return _json({
            'ok': true,
            'data': {
              'items': [
                {'id': 'pac-001'},
              ],
            },
          });
        }
        if (request.url.path == '/api/viagens/VIA-1/passageiros') {
          return _json({
            'ok': true,
            'data': [
              {'id': 'pas-001'},
            ],
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
    final viagensLogistica = await client.buscarLogisticaViagens();
    final motoristas = await client.buscarLogisticaMotoristas();
    final veiculos = await client.buscarLogisticaVeiculos();
    final pacientes = await client.buscarLogisticaPacientes();
    final passageiros = await client.buscarLogisticaPassageiros('VIA-1');
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
    expect(viagensLogistica.single['id'], 'VIA-GERAL-1');
    expect(motoristas.single['id'], 'mot-001');
    expect(veiculos.single['id'], 'vei-001');
    expect(pacientes.single['id'], 'pac-001');
    expect(passageiros.single['id'], 'pas-001');
    expect(checklist, isTrue);
    expect(km, isTrue);
    expect(fluxo, isTrue);
    expect(finalizacao, isTrue);
    expect(panico, isTrue);
    expect(comprovante, isTrue);
    expect(requests, contains('POST /api/driver/login'));
    expect(requests, contains('GET /api/viagens'));
    expect(requests, contains('GET /api/motoristas'));
    expect(requests, contains('GET /api/veiculos'));
    expect(requests, contains('GET /api/pacientes'));
    expect(requests, contains('GET /api/viagens/VIA-1/passageiros'));
    expect(requests, contains('POST /api/driver/trips/VIA-1/checklist'));
    expect(requests, contains('POST /api/driver/panic'));
    expect(requests.any((path) => path.contains('Logistica')), isFalse);
  });
}

http.Response _json(Map<String, dynamic> body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

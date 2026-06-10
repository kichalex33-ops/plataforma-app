import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/trip_model.dart';
import 'api_config.dart';

class DriverApiClient {
  final http.Client client;

  DriverApiClient({http.Client? client}) : client = client ?? http.Client();

  Future<bool> testarConexao() async {
    debugPrint('[API] GET ${ApiConfig.status}');
    try {
      final response = await client
          .get(ApiConfig.uri(ApiConfig.status))
          .timeout(ApiConfig.httpTimeout);
      debugPrint('[API] status ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      debugPrint('[API] testarConexao falhou: $error');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> buscarViagensMockadas() async {
    debugPrint('[API] GET ${ApiConfig.driverTrips}');
    return _getLista(ApiConfig.driverTrips);
  }

  Future<Map<String, dynamic>?> loginMotorista({
    required String identificador,
    required String senha,
    bool lembrar = false,
  }) async {
    debugPrint('[API] POST ${ApiConfig.driverLogin}');
    return _postData(ApiConfig.driverLogin, {
      'identificador': identificador,
      'senha': senha,
      'lembrar': lembrar,
    });
  }

  Future<List<Map<String, dynamic>>> buscarViagensDoMotorista(
    String motoristaId,
  ) async {
    debugPrint('[API] GET ${ApiConfig.driverTrips} motorista=$motoristaId');
    return _getLista('${ApiConfig.driverTrips}?motorista_id=$motoristaId');
  }

  Future<Trip?> fetchCurrentTrip(String motoristaId, {String? token}) async {
    final uri = ApiConfig.uri(
      '${ApiConfig.driverTrips}/active?id=${Uri.encodeQueryComponent(motoristaId)}',
    );
    debugPrint('[API] GET $uri');
    try {
      final response = await client
          .get(
            uri,
            headers: token == null || token.isEmpty
                ? const {}
                : {'Authorization': token},
          )
          .timeout(ApiConfig.httpTimeout);
      debugPrint('[API] active trip -> ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) return Trip.fromJson(data);
        return Trip.fromJson(decoded);
      }
    } catch (error) {
      debugPrint('[API] fetchCurrentTrip falhou: $error');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> buscarAvisosCentral([
    String? motoristaId,
  ]) async {
    debugPrint('[API] GET ${ApiConfig.driverNotices}');
    final query = motoristaId == null || motoristaId.trim().isEmpty
        ? ''
        : '?motorista_id=${Uri.encodeQueryComponent(motoristaId)}';
    return _getLista(
      '${ApiConfig.driverNotices}$query',
      listKeys: const ['avisos'],
    );
  }

  Future<List<Map<String, dynamic>>> buscarLogisticaViagens() async {
    debugPrint('[API] GET ${ApiConfig.logisticaViagens}');
    return _getLista(ApiConfig.logisticaViagens);
  }

  Future<List<Map<String, dynamic>>> buscarLogisticaMotoristas() async {
    debugPrint('[API] GET ${ApiConfig.logisticaMotoristas}');
    return _getLista(ApiConfig.logisticaMotoristas);
  }

  Future<List<Map<String, dynamic>>> buscarLogisticaVeiculos() async {
    debugPrint('[API] GET ${ApiConfig.logisticaVeiculos}');
    return _getLista(ApiConfig.logisticaVeiculos);
  }

  Future<List<Map<String, dynamic>>> buscarLogisticaPacientes() async {
    debugPrint('[API] GET ${ApiConfig.logisticaPacientes}');
    return _getLista(ApiConfig.logisticaPacientes);
  }

  Future<List<Map<String, dynamic>>> buscarLogisticaPassageiros(
    String viagemId,
  ) async {
    final path = ApiConfig.logisticaPassageiros(viagemId);
    debugPrint('[API] GET $path');
    return _getLista(path, listKeys: const ['passageiros', 'items', 'dados']);
  }

  Future<List<Map<String, dynamic>>> buscarEventosRecebidos() async {
    debugPrint('[API] GET ${ApiConfig.driverEvents}');
    return _getLista(ApiConfig.driverEvents);
  }

  Future<List<Map<String, dynamic>>> buscarLocalizacoesRecebidas() async {
    debugPrint('[API] GET ${ApiConfig.driverLocations}');
    return _getLista(ApiConfig.driverLocations);
  }

  Future<List<Map<String, dynamic>>> buscarStatusViagensRecebidos() async {
    debugPrint('[API] GET ${ApiConfig.driverTripStatus}');
    return _getLista(ApiConfig.driverTripStatus);
  }

  Future<List<Map<String, dynamic>>> _getLista(
    String path, {
    List<String> listKeys = const ['items', 'viagens', 'trips', 'dados'],
  }) async {
    try {
      final response = await client
          .get(ApiConfig.uri(path))
          .timeout(ApiConfig.httpTimeout);
      debugPrint('[API] GET $path -> ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      return _extrairLista(response.body, listKeys: listKeys);
    } catch (error) {
      debugPrint('[API] GET $path falhou: $error');
      return const [];
    }
  }

  Future<bool> enviarEvento(Map<String, dynamic> payload) async {
    debugPrint('[EVENTO] POST ${ApiConfig.driverEvents} id=${payload['id']}');
    return _postJson(ApiConfig.driverEvents, payload);
  }

  Future<bool> enviarLocalizacao(Map<String, dynamic> payload) async {
    debugPrint('[API] POST ${ApiConfig.driverLocations}');
    return _postJson(ApiConfig.driverLocations, payload);
  }

  Future<bool> enviarStatusViagem(Map<String, dynamic> payload) async {
    debugPrint('[API] POST ${ApiConfig.driverTripStatus}');
    return _postJson(ApiConfig.driverTripStatus, payload);
  }

  Future<bool> enviarChecklistPreViagem({
    required String viagemId,
    required String motoristaId,
    required Map<String, bool> itens,
    String observacoes = '',
  }) {
    return _postJson('/api/driver/trips/$viagemId/checklist', {
      'motorista_id': motoristaId,
      ...itens,
      'observacoes': observacoes,
    });
  }

  Future<bool> registrarKmInicial({
    required String viagemId,
    required String motoristaId,
    required num kmSaida,
    double? latitude,
    double? longitude,
  }) {
    return _postJson('/api/driver/trips/$viagemId/km-inicial', {
      'motorista_id': motoristaId,
      'km_saida': kmSaida,
      'latitude': ?latitude,
      'longitude': ?longitude,
    });
  }

  Future<bool> enviarFluxoViagem({
    required String viagemId,
    required String action,
    required String motoristaId,
  }) {
    return _postJson('/api/driver/trips/$viagemId/flow', {
      'action': action,
      'motorista_id': motoristaId,
    });
  }

  Future<bool> finalizarViagem({
    required String viagemId,
    required String motoristaId,
    required num kmFinal,
    String resumo = '',
  }) {
    return _postJson('/api/driver/trips/$viagemId/finalizar', {
      'motorista_id': motoristaId,
      'km_final': kmFinal,
      'resumo': resumo,
    });
  }

  Future<bool> acionarPanico({
    required String viagemId,
    required String motoristaId,
    double? latitude,
    double? longitude,
  }) {
    return _postJson('/api/driver/panic', {
      'viagem_id': viagemId,
      'motorista_id': motoristaId,
      'latitude': ?latitude,
      'longitude': ?longitude,
    });
  }

  Future<bool> enviarComprovanteConsulta({
    required String viagemId,
    required String passageiroId,
    required String arquivoNome,
    String tipo = 'foto',
  }) {
    return _postJson('/api/driver/proofs', {
      'viagem_id': viagemId,
      'passageiro_id': passageiroId,
      'arquivo_nome': arquivoNome,
      'tipo': tipo,
    });
  }

  Future<Map<String, dynamic>?> _postData(
    String path,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await client
          .post(
            ApiConfig.uri(path),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.httpTimeout);
      debugPrint('[API] POST $path -> ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) return data;
        return decoded;
      }
    } catch (error) {
      debugPrint('[API] POST $path falhou: $error');
    }
    return null;
  }

  Future<bool> _postJson(String path, Map<String, dynamic> payload) async {
    try {
      final response = await client
          .post(
            ApiConfig.uri(path),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.httpTimeout);
      debugPrint('[API] POST $path -> ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      debugPrint('[API] POST $path falhou: $error');
      return false;
    }
  }

  List<Map<String, dynamic>> _extrairLista(
    String body, {
    List<String> listKeys = const ['items', 'viagens', 'trips', 'dados'],
  }) {
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
      }
      if (data is Map<String, dynamic>) {
        for (final chave in listKeys) {
          final valor = data[chave];
          if (valor is List) {
            return valor
                .whereType<Map>()
                .map(Map<String, dynamic>.from)
                .toList();
          }
        }
      }
      for (final chave in listKeys) {
        final valor = decoded[chave];
        if (valor is List) {
          return valor.whereType<Map>().map(Map<String, dynamic>.from).toList();
        }
      }
    }
    return const [];
  }
}

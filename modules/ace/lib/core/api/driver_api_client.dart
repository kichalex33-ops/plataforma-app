import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
    try {
      final response = await client
          .get(ApiConfig.uri(ApiConfig.driverTrips))
          .timeout(ApiConfig.httpTimeout);
      debugPrint('[API] trips ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      return _extrairLista(response.body);
    } catch (error) {
      debugPrint('[API] buscarViagensMockadas falhou: $error');
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

  List<Map<String, dynamic>> _extrairLista(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
    if (decoded is Map<String, dynamic>) {
      for (final chave in ['items', 'viagens', 'trips', 'dados']) {
        final valor = decoded[chave];
        if (valor is List) {
          return valor.whereType<Map>().map(Map<String, dynamic>.from).toList();
        }
      }
    }
    return const [];
  }
}

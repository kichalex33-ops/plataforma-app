import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:plataforma_logistica_driver/core/api/api_config.dart';

import '../../auth/secure_session_storage.dart';
import '../models/sync_operation_type.dart';
import '../models/sync_queue_item.dart';

class SyncConflictException implements Exception {
  final String message;

  const SyncConflictException(this.message);

  @override
  String toString() => message;
}

class ApiSyncDispatcher {
  final http.Client client;
  final SecureSessionStorage sessionStorage;

  ApiSyncDispatcher({http.Client? client, SecureSessionStorage? sessionStorage})
    : client = client ?? http.Client(),
      sessionStorage = sessionStorage ?? const SecureSessionStorage();

  Future<void> call(SyncQueueItem item) async {
    final session = await sessionStorage.load();
    final token = session?.token;
    if (token == null || token.trim().isEmpty) {
      throw Exception('Sessao ausente para sincronizacao.');
    }

    final response = await client
        .post(
          await _uri(_pathFor(item)),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(item.toJson()),
        )
        .timeout(ApiConfig.httpTimeout);

    if (response.statusCode == 409) {
      throw const SyncConflictException('Conflito detectado na API.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Falha HTTP ${response.statusCode} ao sincronizar ${item.entityType}.',
      );
    }
  }

  String _pathFor(SyncQueueItem item) {
    switch (item.operationType) {
      case SyncOperationType.gps:
        return ApiConfig.driverLocations;
      case SyncOperationType.event:
      case SyncOperationType.audit:
      case SyncOperationType.checklist:
      case SyncOperationType.occurrence:
      case SyncOperationType.fuel:
      case SyncOperationType.proof:
        return ApiConfig.driverEvents;
      case SyncOperationType.create:
      case SyncOperationType.update:
      case SyncOperationType.delete:
        return '/api/driver/sync';
    }
  }

  Future<Uri> _uri(String path) async {
    final pairedServerUrl = await sessionStorage.pairedServerUrl();
    final baseUrl = pairedServerUrl == null || pairedServerUrl.trim().isEmpty
        ? ApiConfig.baseUrl
        : pairedServerUrl.trim();
    return Uri.parse('$baseUrl$path');
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:plataforma_logistica_driver/core/api/api_config.dart';

import 'app_auth_models.dart';
import 'secure_session_storage.dart';

class DriverPairingException implements Exception {
  final String message;

  const DriverPairingException(this.message);

  @override
  String toString() => message;
}

class DriverPairingPayload {
  final String token;
  final String? serverUrl;
  final String? pairingId;

  const DriverPairingPayload({
    required this.token,
    this.serverUrl,
    this.pairingId,
  });

  factory DriverPairingPayload.parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      throw const DriverPairingException('QR Code vazio.');
    }

    final decoded = _tryDecodeJson(value);
    if (decoded != null) {
      return _fromMap(decoded);
    }

    final uri = Uri.tryParse(value);
    if (uri != null && uri.queryParameters.isNotEmpty) {
      final token =
          uri.queryParameters['token'] ??
          uri.queryParameters['pairing_token'] ??
          uri.queryParameters['pareamento'];
      if (token == null || token.trim().isEmpty) {
        throw const DriverPairingException('QR Code sem token de pareamento.');
      }
      return DriverPairingPayload(
        token: token,
        pairingId: uri.queryParameters['id'],
        serverUrl:
            uri.queryParameters['server_url'] ?? uri.queryParameters['api'],
      );
    }

    return DriverPairingPayload(token: value);
  }

  static Map<String, dynamic>? _tryDecodeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
    return null;
  }

  static DriverPairingPayload _fromMap(Map<String, dynamic> json) {
    final token =
        json['token']?.toString() ??
        json['pairing_token']?.toString() ??
        json['pareamento']?.toString();
    if (token == null || token.trim().isEmpty) {
      throw const DriverPairingException('QR Code sem token de pareamento.');
    }
    return DriverPairingPayload(
      token: token,
      pairingId: json['id']?.toString() ?? json['pairing_id']?.toString(),
      serverUrl: json['server_url']?.toString() ?? json['api']?.toString(),
    );
  }
}

class DriverPairingResult {
  final bool paired;
  final String? login;
  final String? temporaryPassword;
  final String? message;
  final AppUser? user;
  final String? token;
  final String? refreshToken;
  final String? serverUrl;

  const DriverPairingResult({
    required this.paired,
    this.login,
    this.temporaryPassword,
    this.message,
    this.user,
    this.token,
    this.refreshToken,
    this.serverUrl,
  });
}

class DriverPairingService {
  final http.Client client;
  final SecureSessionStorage sessionStorage;

  DriverPairingService({
    http.Client? client,
    SecureSessionStorage? sessionStorage,
  }) : client = client ?? http.Client(),
       sessionStorage = sessionStorage ?? const SecureSessionStorage();

  Future<DriverPairingResult> pairFromRawQr(String rawQr) async {
    return confirmPairing(DriverPairingPayload.parse(rawQr));
  }

  Future<DriverPairingResult> confirmPairing(
    DriverPairingPayload payload,
  ) async {
    final serverUrl =
        _normalizeServerUrl(payload.serverUrl) ?? ApiConfig.baseUrl;
    final response = await client
        .post(
          Uri.parse('$serverUrl${ApiConfig.driverPairingConfirm}'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'token': payload.token,
            if (payload.pairingId != null) 'pairing_id': payload.pairingId,
            'platform': 'android',
          }),
        )
        .timeout(ApiConfig.httpTimeout);

    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DriverPairingException(
        _messageFrom(body) ?? 'Nao foi possivel parear este aparelho.',
      );
    }

    final data = _extractData(body);
    final login = _extractString(data, const ['login', 'usuario', 'username']);
    final temporaryPassword = _extractString(data, const [
      'senha',
      'senha_inicial',
      'temporary_password',
      'password',
    ]);
    final token = _extractString(data, const ['token', 'access_token', 'jwt']);
    final refreshToken = _extractString(data, const [
      'refresh_token',
      'refreshToken',
    ]);
    final responseServerUrl =
        _normalizeServerUrl(
          _extractString(data, const ['server_url', 'api']),
        ) ??
        serverUrl;
    final user = _extractUser(data);

    await sessionStorage.savePairing(
      serverUrl: responseServerUrl,
      login: login ?? user?.login,
    );

    if (token != null && user != null) {
      await sessionStorage.save(
        user: user,
        token: token,
        refreshToken: refreshToken,
      );
    }

    return DriverPairingResult(
      paired: true,
      login: login ?? user?.login,
      temporaryPassword: temporaryPassword,
      message: _messageFrom(data) ?? 'Aparelho pareado com sucesso.',
      user: user,
      token: token,
      refreshToken: refreshToken,
      serverUrl: responseServerUrl,
    );
  }

  String? _normalizeServerUrl(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  Map<String, dynamic> _decodeBody(String raw) {
    if (raw.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{'data': decoded};
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return body;
  }

  String? _messageFrom(Map<String, dynamic> body) {
    for (final key in const ['message', 'mensagem', 'error', 'erro']) {
      final value = body[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  String? _extractString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  AppUser? _extractUser(Map<String, dynamic> data) {
    final raw =
        data['usuario'] ?? data['user'] ?? data['motorista'] ?? data['driver'];
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    return AppUser.fromJson({
      'id': json['id']?.toString() ?? json['motorista_id']?.toString() ?? '',
      'nome_completo':
          json['nome_completo']?.toString() ??
          json['nomeCompleto']?.toString() ??
          json['nome']?.toString() ??
          '',
      'login':
          json['login']?.toString() ?? json['identificador']?.toString() ?? '',
      'municipio':
          json['municipio']?.toString() ??
          json['municipio_nome']?.toString() ??
          '',
      'funcao': json['funcao']?.toString() ?? 'Motorista',
      'perfil':
          json['perfil']?.toString() ??
          json['funcao']?.toString() ??
          'motorista',
      'permissoes': Map<String, bool>.from(
        json['permissoes'] as Map? ?? const {'viagens': true},
      ),
      'modulos_permitidos':
          json['modulos_permitidos'] ??
          json['modulosPermitidos'] ??
          const ['logistica'],
      'ativo': json['ativo'] != false && json['status'] != 'inativo',
      'primeiro_acesso':
          json['primeiro_acesso'] == true || json['primeiroAcesso'] == true,
    });
  }
}

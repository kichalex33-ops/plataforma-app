import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:plataforma_logistica_driver/core/api/api_config.dart';

import 'app_auth_models.dart';
import 'secure_session_storage.dart';

class AuthApiException implements Exception {
  final String message;
  final int? statusCode;

  const AuthApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthApiLoginResult {
  final AuthResult authResult;
  final String? token;
  final String? refreshToken;

  const AuthApiLoginResult({
    required this.authResult,
    this.token,
    this.refreshToken,
  });
}

class AuthApiService {
  final http.Client client;
  final SecureSessionStorage sessionStorage;

  AuthApiService({http.Client? client, SecureSessionStorage? sessionStorage})
    : client = client ?? http.Client(),
      sessionStorage = sessionStorage ?? const SecureSessionStorage();

  Future<AuthApiLoginResult> login({
    required String login,
    required String senha,
  }) async {
    final response = await client
        .post(
          await _uri(ApiConfig.driverLogin),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'login': login, 'senha': senha}),
        )
        .timeout(ApiConfig.httpTimeout);

    final body = _decodeBody(response.body);
    if (response.statusCode == 401 || response.statusCode == 403) {
      return AuthApiLoginResult(
        authResult: AuthResult.denied(
          _messageFrom(body) ?? 'Usuario ou senha invalidos.',
        ),
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _messageFrom(body) ?? 'Falha ao autenticar no painel.',
        statusCode: response.statusCode,
      );
    }

    final data = _extractData(body);
    final userMap = _extractUser(data);
    final token = _extractString(data, const ['token', 'access_token', 'jwt']);
    final refreshToken = _extractString(data, const [
      'refresh_token',
      'refreshToken',
    ]);

    if (userMap == null) {
      throw const AuthApiException('Resposta de login sem dados do usuario.');
    }

    final user = _userFromApi(userMap);
    if (!user.temPermissaoAtiva) {
      return const AuthApiLoginResult(
        authResult: AuthResult.denied(
          PanelAuthMessages.permissionDeniedMessage,
        ),
      );
    }

    return AuthApiLoginResult(
      authResult: AuthResult.allowed(user),
      token: token,
      refreshToken: refreshToken,
    );
  }

  Future<void> changePassword({
    required String token,
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final response = await client
        .post(
          await _uri('/api/driver/change-password'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'senha_atual': senhaAtual,
            'nova_senha': novaSenha,
          }),
        )
        .timeout(ApiConfig.httpTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw AuthApiException(
        _messageFrom(body) ?? 'Nao foi possivel alterar a senha.',
        statusCode: response.statusCode,
      );
    }
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

  Map<String, dynamic>? _extractUser(Map<String, dynamic> data) {
    for (final key in const ['usuario', 'user', 'motorista', 'driver']) {
      final value = data[key];
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    if (data.containsKey('perfil') || data.containsKey('nome')) {
      return data;
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

  String? _messageFrom(Map<String, dynamic> body) {
    for (final key in const ['message', 'mensagem', 'error', 'erro']) {
      final value = body[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  AppUser _userFromApi(Map<String, dynamic> json) {
    final perfil = json['perfil']?.toString() ?? json['funcao']?.toString();
    final modulosRaw = json['modulos_permitidos'] ?? json['modulosPermitidos'];
    final modulos = modulosRaw is List
        ? modulosRaw.map((value) => value.toString()).toList(growable: false)
        : const ['logistica'];

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
      'perfil': perfil ?? 'motorista',
      'permissoes': Map<String, bool>.from(
        json['permissoes'] as Map? ?? const {'viagens': true},
      ),
      'modulos_permitidos': modulos,
      'ativo': json['ativo'] != false && json['status'] != 'inativo',
      'primeiro_acesso':
          json['primeiro_acesso'] == true || json['primeiroAcesso'] == true,
    });
  }

  Future<Uri> _uri(String path) async {
    final pairedServerUrl = await sessionStorage.pairedServerUrl();
    final baseUrl = pairedServerUrl == null || pairedServerUrl.trim().isEmpty
        ? ApiConfig.baseUrl
        : pairedServerUrl.trim();
    return Uri.parse('$baseUrl$path');
  }
}

class PanelAuthMessages {
  static const permissionDeniedMessage =
      'Usuario sem permissao ativa. Procure o operador responsavel.';
}

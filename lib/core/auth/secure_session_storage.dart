import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_auth_models.dart';

abstract class SecureKeyValueStore {
  Future<void> write({required String key, required String value});

  Future<String?> read({required String key});

  Future<void> delete({required String key});
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  final FlutterSecureStorage storage;

  const FlutterSecureKeyValueStore({
    this.storage = const FlutterSecureStorage(),
  });

  @override
  Future<void> write({required String key, required String value}) {
    return storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) {
    return storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) {
    return storage.delete(key: key);
  }
}

class MemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _values[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }
}

class SecureSession {
  final AppUser user;
  final String token;
  final String? refreshToken;

  const SecureSession({
    required this.user,
    required this.token,
    this.refreshToken,
  });
}

class SecureSessionStorage {
  static const _userKey = 'auth_user';
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _pairedServerUrlKey = 'paired_server_url';
  static const _pairedLoginKey = 'paired_login';

  final SecureKeyValueStore store;

  const SecureSessionStorage({SecureKeyValueStore? store})
    : store = store ?? const FlutterSecureKeyValueStore();

  Future<void> save({
    required AppUser user,
    required String token,
    String? refreshToken,
  }) async {
    await store.write(key: _userKey, value: jsonEncode(user.toJson()));
    await store.write(key: _tokenKey, value: token);
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      await store.delete(key: _refreshTokenKey);
    } else {
      await store.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<SecureSession?> load() async {
    final rawUser = await store.read(key: _userKey);
    final token = await store.read(key: _tokenKey);
    if (rawUser == null || token == null || token.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawUser);
    if (decoded is! Map) {
      return null;
    }

    return SecureSession(
      user: AppUser.fromJson(Map<String, dynamic>.from(decoded)),
      token: token,
      refreshToken: await store.read(key: _refreshTokenKey),
    );
  }

  Future<String?> token() => store.read(key: _tokenKey);

  Future<void> savePairing({String? serverUrl, String? login}) async {
    if (serverUrl != null && serverUrl.trim().isNotEmpty) {
      await store.write(key: _pairedServerUrlKey, value: serverUrl.trim());
    }
    if (login != null && login.trim().isNotEmpty) {
      await store.write(key: _pairedLoginKey, value: login.trim());
    }
  }

  Future<String?> pairedServerUrl() => store.read(key: _pairedServerUrlKey);

  Future<String?> pairedLogin() => store.read(key: _pairedLoginKey);

  Future<void> clear() async {
    await store.delete(key: _userKey);
    await store.delete(key: _tokenKey);
    await store.delete(key: _refreshTokenKey);
  }
}

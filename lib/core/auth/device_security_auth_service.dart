import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSecurityAuthService {
  static const _linkedLoginKey = 'device_security_linked_login';

  final LocalAuthentication localAuth;

  DeviceSecurityAuthService({LocalAuthentication? localAuth})
    : localAuth = localAuth ?? LocalAuthentication();

  Future<String?> linkedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_linkedLoginKey);
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  Future<bool> hasLinkedUser() async => (await linkedLogin()) != null;

  Future<bool> linkAuthenticatedUser(String login) async {
    final ok = await _authenticate(
      'Confirme sua identidade para ativar a segurança do aparelho.',
    );
    if (!ok) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_linkedLoginKey, login);
  }

  Future<String?> unlockLinkedUser() async {
    final login = await linkedLogin();
    if (login == null) return null;
    final ok = await _authenticate(
      'Desbloqueie o app com a segurança do aparelho.',
    );
    return ok ? login : null;
  }

  Future<void> clearLinkedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_linkedLoginKey);
  }

  Future<bool> _authenticate(String reason) async {
    final supported =
        await localAuth.canCheckBiometrics ||
        await localAuth.isDeviceSupported();
    if (!supported) return false;
    return localAuth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  }
}

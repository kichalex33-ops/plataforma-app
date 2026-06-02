import 'package:local_auth/local_auth.dart';

class GodModeValidationResult {
  final bool allowed;
  final String? message;

  const GodModeValidationResult.allowed()
      : allowed = true,
        message = null;

  const GodModeValidationResult.denied(this.message) : allowed = false;
}

class GodModeAuthService {
  static const godModeLogin = 'GODMODE';
  static const godModePassword = 'app2026';

  final LocalAuthentication localAuth;

  GodModeAuthService({LocalAuthentication? localAuth})
      : localAuth = localAuth ?? LocalAuthentication();

  Future<GodModeValidationResult> validateGodModeAccess({
    required String login,
    required String password,
    bool requireBiometrics = false,
  }) async {
    final authenticated = login.trim().toUpperCase() == godModeLogin;
    final hasPermission = authenticated;
    final validPassword = password.trim() == godModePassword;

    if (!authenticated || !hasPermission || !validPassword) {
      return const GodModeValidationResult.denied('Acesso GOD MODE negado.');
    }

    if (requireBiometrics) {
      final canCheck = await localAuth.canCheckBiometrics ||
          await localAuth.isDeviceSupported();
      if (!canCheck) {
        return const GodModeValidationResult.denied(
          'Biometria indisponível neste aparelho.',
        );
      }
      final ok = await localAuth.authenticate(
        localizedReason: 'Confirme sua identidade para ativar o GOD MODE.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!ok) {
        return const GodModeValidationResult.denied(
          'Biometria não confirmada.',
        );
      }
    }

    return const GodModeValidationResult.allowed();
  }
}

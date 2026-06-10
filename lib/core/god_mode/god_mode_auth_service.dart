import 'package:local_auth/local_auth.dart';
import 'package:plataforma_logistica_driver/core/api/api_config.dart';

class GodModeValidationResult {
  final bool allowed;
  final String? message;

  const GodModeValidationResult.allowed() : allowed = true, message = null;

  const GodModeValidationResult.denied(this.message) : allowed = false;
}

class GodModeAuthService {
  static const godModeLogin = 'GODMODE';
  static const _godModeEnabled = bool.fromEnvironment(
    'GOD_MODE_ENABLED',
    defaultValue: false,
  );
  static const _godModePassword = String.fromEnvironment('GOD_MODE_PASSWORD');

  final LocalAuthentication localAuth;
  final bool enabled;
  final bool production;
  final String configuredPassword;

  GodModeAuthService({
    LocalAuthentication? localAuth,
    bool? enabled,
    bool? production,
    String? configuredPassword,
  }) : localAuth = localAuth ?? LocalAuthentication(),
       enabled = enabled ?? _godModeEnabled,
       production = production ?? ApiConfig.isProducao,
       configuredPassword = configuredPassword ?? _godModePassword;

  Future<GodModeValidationResult> validateGodModeAccess({
    required String login,
    required String password,
    bool requireBiometrics = false,
  }) async {
    if (production || !enabled || configuredPassword.trim().isEmpty) {
      return const GodModeValidationResult.denied(
        'GOD MODE indisponivel neste ambiente.',
      );
    }

    final authenticated = login.trim().toUpperCase() == godModeLogin;
    final hasPermission = authenticated;
    final validPassword = password.trim() == configuredPassword;

    if (!authenticated || !hasPermission || !validPassword) {
      return const GodModeValidationResult.denied('Acesso GOD MODE negado.');
    }

    if (requireBiometrics) {
      final canCheck =
          await localAuth.canCheckBiometrics ||
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

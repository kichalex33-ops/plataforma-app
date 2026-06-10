import 'package:flutter_test/flutter_test.dart';
import 'package:plataforma_logistica/core/god_mode/god_mode_auth_service.dart';

void main() {
  group('GodModeAuthService', () {
    test('nega GOD MODE por padrao sem flag de ambiente', () async {
      final service = GodModeAuthService(
        enabled: false,
        production: false,
        configuredPassword: 'senha-temporaria',
      );

      final result = await service.validateGodModeAccess(
        login: 'GODMODE',
        password: 'senha-temporaria',
      );

      expect(result.allowed, isFalse);
      expect(result.message, 'GOD MODE indisponivel neste ambiente.');
    });

    test('nega GOD MODE em producao mesmo configurado', () async {
      final service = GodModeAuthService(
        enabled: true,
        production: true,
        configuredPassword: 'senha-temporaria',
      );

      final result = await service.validateGodModeAccess(
        login: 'GODMODE',
        password: 'senha-temporaria',
      );

      expect(result.allowed, isFalse);
      expect(result.message, 'GOD MODE indisponivel neste ambiente.');
    });

    test(
      'libera GOD MODE somente fora de producao com senha injetada',
      () async {
        final service = GodModeAuthService(
          enabled: true,
          production: false,
          configuredPassword: 'senha-temporaria',
        );

        final result = await service.validateGodModeAccess(
          login: 'GODMODE',
          password: 'senha-temporaria',
        );

        expect(result.allowed, isTrue);
        expect(result.message, isNull);
      },
    );

    test('nega GOD MODE com credenciais incorretas', () async {
      final service = GodModeAuthService(
        enabled: true,
        production: false,
        configuredPassword: 'senha-temporaria',
      );

      final result = await service.validateGodModeAccess(
        login: 'Alex',
        password: '1234',
      );

      expect(result.allowed, isFalse);
      expect(result.message, 'Acesso GOD MODE negado.');
    });
  });
}

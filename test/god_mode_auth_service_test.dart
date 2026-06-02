import 'package:flutter_test/flutter_test.dart';
import 'package:andrade_demo_unificada/core/god_mode/god_mode_auth_service.dart';

void main() {
  group('GodModeAuthService', () {
    test('libera GOD MODE com credenciais locais corretas', () async {
      final service = GodModeAuthService();

      final result = await service.validateGodModeAccess(
        login: 'GODMODE',
        password: 'app2026',
      );

      expect(result.allowed, isTrue);
      expect(result.message, isNull);
    });

    test('nega GOD MODE com credenciais incorretas', () async {
      final service = GodModeAuthService();

      final result = await service.validateGodModeAccess(
        login: 'Alex',
        password: '1234',
      );

      expect(result.allowed, isFalse);
      expect(result.message, 'Acesso GOD MODE negado.');
    });
  });
}

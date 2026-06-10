import 'package:flutter_test/flutter_test.dart';
import 'package:plataforma_logistica/core/auth/driver_pairing_service.dart';
import 'package:plataforma_logistica/core/auth/secure_session_storage.dart';

void main() {
  group('DriverPairingPayload', () {
    test('le QR em JSON', () {
      final payload = DriverPairingPayload.parse(
        '{"token":"abc","server_url":"http://10.0.0.4:3000","pairing_id":"p1"}',
      );

      expect(payload.token, 'abc');
      expect(payload.serverUrl, 'http://10.0.0.4:3000');
      expect(payload.pairingId, 'p1');
    });

    test('le QR em URL', () {
      final payload = DriverPairingPayload.parse(
        'plataforma-logistica://pair?token=abc&server_url=http://10.0.0.4:3000',
      );

      expect(payload.token, 'abc');
      expect(payload.serverUrl, 'http://10.0.0.4:3000');
    });

    test('recusa QR sem token', () {
      expect(
        () =>
            DriverPairingPayload.parse('{"server_url":"http://10.0.0.4:3000"}'),
        throwsA(isA<DriverPairingException>()),
      );
    });
  });

  group('SecureSessionStorage pareamento', () {
    test('salva servidor e login pareados sem senha inicial', () async {
      final storage = SecureSessionStorage(store: MemorySecureKeyValueStore());

      await storage.savePairing(
        serverUrl: 'http://10.0.0.4:3000',
        login: 'motorista.login',
      );

      expect(await storage.pairedServerUrl(), 'http://10.0.0.4:3000');
      expect(await storage.pairedLogin(), 'motorista.login');
      expect(await storage.load(), isNull);
    });
  });
}

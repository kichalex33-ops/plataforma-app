import 'package:flutter_test/flutter_test.dart';
import 'package:plataforma_logistica/core/auth/access_router.dart';
import 'package:plataforma_logistica/core/auth/app_auth_models.dart';
import 'package:plataforma_logistica/core/auth/auth_api_service.dart';
import 'package:plataforma_logistica/core/auth/panel_auth_service.dart';
import 'package:plataforma_logistica/core/auth/secure_session_storage.dart';

void main() {
  group('PanelAuthService', () {
    test(
      'autentica motorista retornado pelo painel e salva sessao segura',
      () async {
        final sessionStorage = SecureSessionStorage(
          store: MemorySecureKeyValueStore(),
        );
        final service = PanelAuthService(
          apiService: _FakeAuthApiService(
            result: AuthApiLoginResult(
              authResult: AuthResult.allowed(_motorista()),
              token: 'token-real',
            ),
          ),
          sessionStorage: sessionStorage,
        );

        final result = await service.authenticate(
          login: 'motorista',
          senha: 'senha',
        );
        final session = await sessionStorage.load();

        expect(result.allowed, isTrue);
        expect(result.user?.perfil, AppProfile.motorista);
        expect(result.user?.modulosPermitidos, [AppModule.logistica]);
        expect(session?.token, 'token-real');
        expect(session?.user.login, 'motorista');
      },
    );

    test('nega usuario inativo ou sem permissao', () async {
      final service = PanelAuthService(
        apiService: _FakeAuthApiService(
          result: const AuthApiLoginResult(
            authResult: AuthResult.denied(
              PanelAuthService.permissionDeniedMessage,
            ),
          ),
        ),
        sessionStorage: SecureSessionStorage(
          store: MemorySecureKeyValueStore(),
        ),
      );

      final result = await service.authenticate(
        login: 'inativo',
        senha: 'senha',
      );

      expect(result.allowed, isFalse);
      expect(result.message, PanelAuthService.permissionDeniedMessage);
    });

    test('altera senha via API usando token armazenado', () async {
      final fakeApi = _FakeAuthApiService(
        result: AuthApiLoginResult(
          authResult: AuthResult.allowed(_motorista(primeiroAcesso: true)),
          token: 'token-real',
        ),
      );
      final sessionStorage = SecureSessionStorage(
        store: MemorySecureKeyValueStore(),
      );
      final service = PanelAuthService(
        apiService: fakeApi,
        sessionStorage: sessionStorage,
      );

      await service.authenticate(login: 'motorista', senha: 'senha');

      expect(
        () => service.alterarSenha(
          login: 'motorista',
          senhaAtual: 'senha',
          novaSenha: '123',
          confirmarNovaSenha: '123',
        ),
        throwsA(isA<AuthValidationException>()),
      );

      final changed = await service.alterarSenha(
        login: 'motorista',
        senhaAtual: 'senha',
        novaSenha: 'Nova123',
        confirmarNovaSenha: 'Nova123',
      );

      expect(changed, isTrue);
      expect(fakeApi.changedPassword, isTrue);
      expect((await sessionStorage.load())?.user.primeiroAcesso, isFalse);
    });
  });

  group('AccessRouter', () {
    test('motorista com apenas logistica entra direto no modulo motorista', () {
      expect(
        AccessRouter.resolve(_motorista()),
        AccessDestination.logisticaMotorista,
      );
    });

    test('somente o modulo logistica fica disponivel no app atual', () {
      final user = AppUser(
        id: '2',
        nomeCompleto: 'Operador',
        login: 'operador',
        municipio: 'Municipio',
        funcao: 'Operador',
        perfil: AppProfile.operadorLogistica,
        permissoes: const {'viagens': true},
        modulosPermitidos: const [AppModule.logistica],
        ativo: true,
        primeiroAcesso: false,
      );

      expect(AppModule.values, const [AppModule.logistica]);
      expect(AccessRouter.resolve(user), AccessDestination.operadorLogistica);
    });
  });
}

AppUser _motorista({bool primeiroAcesso = false}) {
  return AppUser(
    id: '1',
    nomeCompleto: 'Motorista Teste',
    login: 'motorista',
    municipio: 'Municipio',
    funcao: 'Motorista',
    perfil: AppProfile.motorista,
    permissoes: const {'viagens': true},
    modulosPermitidos: const [AppModule.logistica],
    ativo: true,
    primeiroAcesso: primeiroAcesso,
  );
}

class _FakeAuthApiService extends AuthApiService {
  final AuthApiLoginResult result;
  bool changedPassword = false;

  _FakeAuthApiService({required this.result});

  @override
  Future<AuthApiLoginResult> login({
    required String login,
    required String senha,
  }) async {
    return result;
  }

  @override
  Future<void> changePassword({
    required String token,
    required String senhaAtual,
    required String novaSenha,
  }) async {
    changedPassword = true;
  }
}

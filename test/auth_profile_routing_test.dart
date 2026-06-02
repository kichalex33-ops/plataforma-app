import 'package:flutter_test/flutter_test.dart';
import 'package:andrade_demo_unificada/core/auth/access_router.dart';
import 'package:andrade_demo_unificada/core/auth/app_auth_models.dart';
import 'package:andrade_demo_unificada/core/auth/panel_auth_service.dart';

void main() {
  group('PanelAuthService', () {
    test('autentica motorista cadastrado no painel', () async {
      final service = PanelAuthService();

      final result = await service.authenticate(login: 'Alexk', senha: '1234');

      expect(result.allowed, isTrue);
      expect(result.user?.nomeCompleto, 'Alex Kich');
      expect(result.user?.municipio, 'Município Demo');
      expect(result.user?.perfil, AppProfile.motorista);
      expect(result.user?.modulosPermitidos, [AppModule.logistica]);
    });

    test('nega usuario inativo ou sem permissao', () async {
      final service = PanelAuthService();

      final result = await service.authenticate(
        login: 'Inativo',
        senha: '1234',
      );

      expect(result.allowed, isFalse);
      expect(
        result.message,
        'Usuário sem permissão ativa. Procure o operador responsável.',
      );
    });

    test('altera senha validando senha atual e força minima', () async {
      final service = PanelAuthService();

      expect(
        () => service.alterarSenha(
          login: 'Alexk',
          senhaAtual: 'errada',
          novaSenha: 'Nova123',
          confirmarNovaSenha: 'Nova123',
        ),
        throwsA(isA<AuthValidationException>()),
      );

      expect(
        () => service.alterarSenha(
          login: 'Alexk',
          senhaAtual: '1234',
          novaSenha: '123',
          confirmarNovaSenha: '123',
        ),
        throwsA(isA<AuthValidationException>()),
      );

      final changed = await service.alterarSenha(
        login: 'Alexk',
        senhaAtual: '1234',
        novaSenha: 'Nova123',
        confirmarNovaSenha: 'Nova123',
      );

      expect(changed, isTrue);
      final oldPassword = await service.authenticate(
        login: 'Alexk',
        senha: '1234',
      );
      final newPassword = await service.authenticate(
        login: 'Alexk',
        senha: 'Nova123',
      );
      expect(oldPassword.allowed, isFalse);
      expect(newPassword.allowed, isTrue);
    });
  });

  group('AccessRouter', () {
    test('motorista com apenas logistica entra direto no modulo motorista', () {
      final user = AppUser(
        id: '1',
        nomeCompleto: 'Motorista',
        login: 'motorista',
        municipio: 'Município',
        funcao: 'Motorista',
        perfil: AppProfile.motorista,
        permissoes: const {'viagens': true},
        modulosPermitidos: const [AppModule.logistica],
        ativo: true,
        primeiroAcesso: false,
      );

      expect(AccessRouter.resolve(user), AccessDestination.logisticaMotorista);
    });

    test('usuario com mais de um modulo ve seleção filtrada', () {
      final user = AppUser(
        id: '2',
        nomeCompleto: 'Supervisor',
        login: 'supervisor',
        municipio: 'Município',
        funcao: 'Supervisor',
        perfil: AppProfile.operadorLogistica,
        permissoes: const {'viagens': true, 'ace': true},
        modulosPermitidos: const [AppModule.logistica, AppModule.ace],
        ativo: true,
        primeiroAcesso: false,
      );

      expect(AccessRouter.resolve(user), AccessDestination.moduleSelector);
    });
  });
}

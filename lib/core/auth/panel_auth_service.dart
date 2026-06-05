import 'app_auth_models.dart';

class PanelAuthService {
  static const permissionDeniedMessage =
      'Usuario sem permissao ativa. Procure o operador responsavel.';

  final Map<String, _PanelUserRecord> _records = _initialRecords();

  static Map<String, _PanelUserRecord> _initialRecords() => {
    'alexk': const _PanelUserRecord(
      user: AppUser(
        id: 'motorista-alexk',
        nomeCompleto: 'Alex Kich',
        login: 'Alexk',
        municipio: 'Municipio Demo',
        funcao: 'Motorista',
        perfil: AppProfile.motorista,
        permissoes: {'viagens': true, 'checklists': true, 'ocorrencias': true},
        modulosPermitidos: [AppModule.logistica],
        ativo: true,
        primeiroAcesso: true,
      ),
      senha: '1234',
    ),
    'barbara': const _PanelUserRecord(
      user: AppUser(
        id: 'motorista-barbara',
        nomeCompleto: 'Barbara',
        login: 'Barbara',
        municipio: 'Municipio Demo',
        funcao: 'Motorista',
        perfil: AppProfile.motorista,
        permissoes: {'viagens': true, 'checklists': true},
        modulosPermitidos: [AppModule.logistica],
        ativo: true,
        primeiroAcesso: false,
      ),
      senha: '1234',
    ),
    'gilyan': const _PanelUserRecord(
      user: AppUser(
        id: 'motorista-gilyan',
        nomeCompleto: 'Gilyan',
        login: 'Gilyan',
        municipio: 'Municipio Demo',
        funcao: 'Motorista',
        perfil: AppProfile.motorista,
        permissoes: {'viagens': true, 'checklists': true},
        modulosPermitidos: [AppModule.logistica],
        ativo: true,
        primeiroAcesso: false,
      ),
      senha: '1234',
    ),
    'operador': const _PanelUserRecord(
      user: AppUser(
        id: 'operador-logistica',
        nomeCompleto: 'Operador Logistica',
        login: 'operador',
        municipio: 'Municipio Demo',
        funcao: 'Controlador logistico',
        perfil: AppProfile.operadorLogistica,
        permissoes: {'painel_operacional': true},
        modulosPermitidos: [AppModule.logistica],
        ativo: true,
        primeiroAcesso: false,
      ),
      senha: '1234',
    ),
    'inativo': const _PanelUserRecord(
      user: AppUser(
        id: 'inativo',
        nomeCompleto: 'Usuario Inativo',
        login: 'Inativo',
        municipio: 'Municipio Demo',
        funcao: 'Motorista',
        perfil: AppProfile.motorista,
        permissoes: {},
        modulosPermitidos: [AppModule.logistica],
        ativo: false,
        primeiroAcesso: false,
      ),
      senha: '1234',
    ),
  };

  Future<AuthResult> authenticate({
    required String login,
    required String senha,
  }) async {
    final record = _records[login.trim().toLowerCase()];
    if (record == null || record.senha != senha.trim()) {
      return const AuthResult.denied('Usuario ou senha invalidos.');
    }
    if (!record.user.temPermissaoAtiva) {
      return const AuthResult.denied(permissionDeniedMessage);
    }
    return AuthResult.allowed(record.user);
  }

  Future<AppUser?> userByLogin(String login) async {
    return _records[login.trim().toLowerCase()]?.user;
  }

  Future<bool> alterarSenha({
    required String login,
    required String senhaAtual,
    required String novaSenha,
    required String confirmarNovaSenha,
  }) async {
    final key = login.trim().toLowerCase();
    final record = _records[key];
    if (record == null) {
      throw const AuthValidationException('Usuario nao encontrado.');
    }
    if (record.senha != senhaAtual.trim()) {
      throw const AuthValidationException('Senha atual invalida.');
    }
    final nova = novaSenha.trim();
    if (nova != confirmarNovaSenha.trim()) {
      throw const AuthValidationException('As senhas nao conferem.');
    }
    if (!_senhaForte(nova)) {
      throw const AuthValidationException(
        'A nova senha deve ter pelo menos 6 caracteres, letras e numeros.',
      );
    }

    _records[key] = _PanelUserRecord(
      user: record.user.copyWith(primeiroAcesso: false),
      senha: nova,
    );
    return true;
  }

  bool _senhaForte(String senha) {
    final hasMinLength = senha.length >= 6;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(senha);
    final hasNumber = RegExp(r'\d').hasMatch(senha);
    return hasMinLength && hasLetter && hasNumber;
  }
}

class _PanelUserRecord {
  final AppUser user;
  final String senha;

  const _PanelUserRecord({required this.user, required this.senha});
}

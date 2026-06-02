enum AppProfile {
  motorista,
  operadorLogistica,
  ace,
  acs,
  administrador,
}

enum AppModule {
  logistica,
  ace,
  acs,
}

class AppUser {
  final String id;
  final String nomeCompleto;
  final String login;
  final String municipio;
  final String funcao;
  final AppProfile perfil;
  final Map<String, bool> permissoes;
  final List<AppModule> modulosPermitidos;
  final bool ativo;
  final bool primeiroAcesso;

  const AppUser({
    required this.id,
    required this.nomeCompleto,
    required this.login,
    required this.municipio,
    required this.funcao,
    required this.perfil,
    required this.permissoes,
    required this.modulosPermitidos,
    required this.ativo,
    required this.primeiroAcesso,
  });

  bool get temPermissaoAtiva => ativo && modulosPermitidos.isNotEmpty;

  AppUser copyWith({bool? primeiroAcesso}) {
    return AppUser(
      id: id,
      nomeCompleto: nomeCompleto,
      login: login,
      municipio: municipio,
      funcao: funcao,
      perfil: perfil,
      permissoes: permissoes,
      modulosPermitidos: modulosPermitidos,
      ativo: ativo,
      primeiroAcesso: primeiroAcesso ?? this.primeiroAcesso,
    );
  }
}

class AuthResult {
  final bool allowed;
  final AppUser? user;
  final String? message;

  const AuthResult.allowed(this.user)
      : allowed = true,
        message = null;

  const AuthResult.denied(this.message)
      : allowed = false,
        user = null;
}

class AuthValidationException implements Exception {
  final String message;

  const AuthValidationException(this.message);

  @override
  String toString() => message;
}

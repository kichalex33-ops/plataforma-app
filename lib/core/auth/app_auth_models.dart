enum AppProfile { motorista, operadorLogistica, administrador }

enum AppModule { logistica }

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

  bool get temPermissaoAtiva =>
      ativo && modulosPermitidos.contains(AppModule.logistica);

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome_completo': nomeCompleto,
      'login': login,
      'municipio': municipio,
      'funcao': funcao,
      'perfil': perfil.name,
      'permissoes': permissoes,
      'modulos_permitidos': modulosPermitidos
          .map((module) => module.name)
          .toList(),
      'ativo': ativo,
      'primeiro_acesso': primeiroAcesso,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final modulos = (json['modulos_permitidos'] as List? ?? const <Object?>[])
        .map((value) => value.toString())
        .map(_parseModule)
        .whereType<AppModule>()
        .toList(growable: false);

    return AppUser(
      id: json['id']?.toString() ?? '',
      nomeCompleto:
          json['nome_completo']?.toString() ??
          json['nomeCompleto']?.toString() ??
          '',
      login: json['login']?.toString() ?? '',
      municipio: json['municipio']?.toString() ?? '',
      funcao: json['funcao']?.toString() ?? '',
      perfil: _parseProfile(json['perfil']?.toString()),
      permissoes: Map<String, bool>.from(
        json['permissoes'] as Map? ?? const {},
      ),
      modulosPermitidos: modulos.isEmpty
          ? const [AppModule.logistica]
          : modulos,
      ativo: json['ativo'] != false,
      primeiroAcesso:
          json['primeiro_acesso'] == true || json['primeiroAcesso'] == true,
    );
  }

  static AppProfile _parseProfile(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'operador_logistica':
      case 'operadorlogistica':
      case 'operador':
        return AppProfile.operadorLogistica;
      case 'administrador':
      case 'admin':
        return AppProfile.administrador;
      case 'motorista':
      default:
        return AppProfile.motorista;
    }
  }

  static AppModule? _parseModule(String value) {
    switch (value.trim().toLowerCase()) {
      case 'logistica':
      case 'logística':
        return AppModule.logistica;
      default:
        return null;
    }
  }
}

class AuthResult {
  final bool allowed;
  final AppUser? user;
  final String? message;

  const AuthResult.allowed(this.user) : allowed = true, message = null;

  const AuthResult.denied(this.message) : allowed = false, user = null;
}

class AuthValidationException implements Exception {
  final String message;

  const AuthValidationException(this.message);

  @override
  String toString() => message;
}

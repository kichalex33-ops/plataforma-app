enum PapelUsuario {
  ace,
  acs,
  motorista,
  coordenador,
  administrador,
  gestao,
}

extension PapelUsuarioLabel on PapelUsuario {
  String get label {
    return switch (this) {
      PapelUsuario.ace => 'ACE',
      PapelUsuario.acs => 'ACS',
      PapelUsuario.motorista => 'Motorista',
      PapelUsuario.coordenador => 'Coordenador',
      PapelUsuario.administrador => 'Administrador',
      PapelUsuario.gestao => 'Gestao',
    };
  }
}

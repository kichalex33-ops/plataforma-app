import 'app_auth_models.dart';

enum AccessDestination {
  logisticaMotorista,
  operadorLogistica,
  moduleSelector,
  denied,
}

class AccessRouter {
  static AccessDestination resolve(AppUser user) {
    if (!user.temPermissaoAtiva) return AccessDestination.denied;
    if (user.modulosPermitidos.length > 1) {
      return AccessDestination.moduleSelector;
    }

    return switch (user.perfil) {
      AppProfile.motorista => AccessDestination.logisticaMotorista,
      AppProfile.operadorLogistica => AccessDestination.operadorLogistica,
      AppProfile.administrador => AccessDestination.moduleSelector,
    };
  }
}

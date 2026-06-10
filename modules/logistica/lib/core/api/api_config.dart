class ApiConfig {
  ApiConfig._();

  static const String ambiente = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.0.4:3000',
  );

  static const Duration httpTimeout = Duration(seconds: 10);

  static bool get isDev => ambiente == 'dev';
  static bool get isHomologacao => ambiente == 'homologacao';
  static bool get isProducao => ambiente == 'producao';

  static const String status = '/api/status';
  static const String driverTrips = '/api/driver/trips';
  static const String driverLogin = '/api/driver/login';
  static const String driverPairingConfirm = '/api/driver/pairing/confirm';
  static const String driverNotices = '/api/driver/notices';
  static const String driverEvents = '/api/driver/events';
  static const String driverLocations = '/api/driver/locations';
  static const String driverTripStatus = '/api/driver/trips/status';
  static const String logisticaViagens = '/api/viagens';
  static const String logisticaMotoristas = '/api/motoristas';
  static const String logisticaVeiculos = '/api/veiculos';
  static const String logisticaPacientes = '/api/pacientes';

  static String logisticaPassageiros(String viagemId) {
    return '/api/viagens/$viagemId/passageiros';
  }

  static Uri uri(String path) => Uri.parse('$baseUrl$path');

  static void validarAmbiente() {
    if (isProducao && !baseUrl.startsWith('https://')) {
      throw StateError('API_BASE_URL de producao deve usar HTTPS.');
    }
  }
}

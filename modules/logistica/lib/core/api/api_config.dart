class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://10.0.0.4:3000';
  static const Duration httpTimeout = Duration(seconds: 5);

  static const String status = '/api/status';
  static const String driverTrips = '/api/driver/trips';
  static const String driverLogin = '/api/driver/login';
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
}

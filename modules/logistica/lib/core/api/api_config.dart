class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://10.0.0.3:3000';
  static const Duration httpTimeout = Duration(seconds: 5);

  static const String status = '/api/status';
  static const String driverTrips = '/api/driver/trips';
  static const String driverLogin = '/api/driver/login';
  static const String driverNotices = '/api/driver/notices';
  static const String driverEvents = '/api/driver/events';
  static const String driverLocations = '/api/driver/locations';
  static const String driverTripStatus = '/api/driver/trips/status';
  static const String logisaudeViagens = '/api/logisaude/viagens';
  static const String logisaudeMotoristas = '/api/logisaude/motoristas';
  static const String logisaudeVeiculos = '/api/logisaude/veiculos';
  static const String logisaudePacientes = '/api/logisaude/pacientes';
  static const String logisaudePassageiros = '/api/logisaude/passageiros';

  static Uri uri(String path) => Uri.parse('$baseUrl$path');
}

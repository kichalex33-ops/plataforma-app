class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://10.0.0.3:3000';
  static const Duration httpTimeout = Duration(seconds: 5);

  static const String status = '/api/status';
  static const String driverTrips = '/api/driver/trips';
  static const String driverEvents = '/api/driver/events';
  static const String driverLocations = '/api/driver/locations';
  static const String driverTripStatus = '/api/driver/trips/status';

  static Uri uri(String path) => Uri.parse('$baseUrl$path');
}

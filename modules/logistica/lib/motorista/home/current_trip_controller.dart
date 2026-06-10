import 'package:flutter/foundation.dart';

import '../../core/api/driver_api_client.dart';
import '../../models/trip_model.dart';

class CurrentTripController extends ChangeNotifier {
  final DriverApiClient apiClient;

  CurrentTripController({DriverApiClient? apiClient})
    : apiClient = apiClient ?? DriverApiClient();

  Trip? trip;
  bool loading = false;
  String? error;

  Future<void> load(String motoristaId) async {
    if (motoristaId.trim().isEmpty) return;
    loading = true;
    error = null;
    notifyListeners();

    try {
      trip = await apiClient.fetchCurrentTrip(motoristaId);
    } catch (exception) {
      error = exception.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

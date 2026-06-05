import '../connectivity/models/connectivity_status.dart';
import '../connectivity/services/connectivity_service.dart';

class ConnectivityAgent {
  final ConnectivityService service;

  ConnectivityAgent({required this.service});

  ConnectivityStatus get status => service.status;

  bool get canSync => service.canSync;

  void addListener(ConnectivityListener listener) {
    service.addListener(listener);
  }

  void removeListener(ConnectivityListener listener) {
    service.removeListener(listener);
  }

  Future<void> updateStatus(ConnectivityStatus status) {
    return service.updateStatus(status);
  }
}

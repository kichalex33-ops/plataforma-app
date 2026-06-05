import 'dart:async';

import '../models/connectivity_status.dart';

typedef ConnectivityListener =
    FutureOr<void> Function(ConnectivityStatus status);

class ConnectivityService {
  ConnectivityStatus _status;
  final List<ConnectivityListener> _listeners = <ConnectivityListener>[];

  ConnectivityService({
    ConnectivityStatus initialStatus = ConnectivityStatus.offline,
  }) : _status = initialStatus;

  ConnectivityStatus get status => _status;

  bool get canSync => _status.canSync;

  void addListener(ConnectivityListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ConnectivityListener listener) {
    _listeners.remove(listener);
  }

  Future<void> updateStatus(ConnectivityStatus status) async {
    if (_status == status) return;
    _status = status;
    for (final listener in List<ConnectivityListener>.from(_listeners)) {
      await Future<void>.value(listener(status));
    }
  }
}

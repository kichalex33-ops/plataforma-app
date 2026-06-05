enum ConnectivityStatus { wifi, mobile, offline, unstable }

extension ConnectivityStatusExtension on ConnectivityStatus {
  String get value {
    switch (this) {
      case ConnectivityStatus.wifi:
        return 'wifi';
      case ConnectivityStatus.mobile:
        return 'mobile';
      case ConnectivityStatus.offline:
        return 'offline';
      case ConnectivityStatus.unstable:
        return 'unstable';
    }
  }

  String get label {
    switch (this) {
      case ConnectivityStatus.wifi:
        return 'Wi-Fi';
      case ConnectivityStatus.mobile:
        return '3G/4G';
      case ConnectivityStatus.offline:
        return 'Offline';
      case ConnectivityStatus.unstable:
        return 'Conexao instavel';
    }
  }

  bool get canSync {
    switch (this) {
      case ConnectivityStatus.wifi:
      case ConnectivityStatus.mobile:
        return true;
      case ConnectivityStatus.offline:
      case ConnectivityStatus.unstable:
        return false;
    }
  }

  static ConnectivityStatus parse(String? value) {
    switch (value) {
      case 'wifi':
        return ConnectivityStatus.wifi;
      case 'mobile':
        return ConnectivityStatus.mobile;
      case 'unstable':
        return ConnectivityStatus.unstable;
      case 'offline':
      default:
        return ConnectivityStatus.offline;
    }
  }
}

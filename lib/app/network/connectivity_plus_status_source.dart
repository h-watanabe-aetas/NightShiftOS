import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_status_source.dart';

typedef ConnectivityChanges = Stream<List<ConnectivityResult>> Function();

class ConnectivityPlusStatusSource implements ConnectivityStatusSource {
  ConnectivityPlusStatusSource({
    Connectivity? connectivity,
    ConnectivityChanges? onConnectivityChanged,
  })  : _connectivity = connectivity ?? Connectivity(),
        _onConnectivityChanged = onConnectivityChanged;

  final Connectivity _connectivity;
  final ConnectivityChanges? _onConnectivityChanged;

  @override
  Stream<bool> get onStatusChanged {
    final source =
        _onConnectivityChanged?.call() ?? _connectivity.onConnectivityChanged;
    return source.map(isOnline).distinct();
  }

  static bool isOnline(List<ConnectivityResult> statuses) {
    return statuses.any((status) => status != ConnectivityResult.none);
  }
}

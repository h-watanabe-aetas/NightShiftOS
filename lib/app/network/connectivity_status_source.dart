abstract class ConnectivityStatusSource {
  Stream<bool> get onStatusChanged;
}

class NoopConnectivityStatusSource implements ConnectivityStatusSource {
  const NoopConnectivityStatusSource();

  @override
  Stream<bool> get onStatusChanged => const Stream.empty();
}

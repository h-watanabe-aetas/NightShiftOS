import 'permissions_gateway.dart';

class OnboardingWizard {
  OnboardingWizard({required PermissionsGateway gateway}) : _gateway = gateway;

  static const List<AppPermission> flowOrder = [
    AppPermission.locationAlways,
    AppPermission.notifications,
    AppPermission.bluetoothScan,
  ];

  final PermissionsGateway _gateway;

  Future<List<AppPermission>> pendingPermissions() async {
    final pending = <AppPermission>[];
    for (final permission in flowOrder) {
      final status = await _gateway.getStatus(permission);
      if (status != PermissionState.granted) {
        pending.add(permission);
      }
    }
    return pending;
  }

  Future<bool> canFinish() async {
    final pending = await pendingPermissions();
    return pending.isEmpty;
  }

  Future<PermissionState> requestPermission(AppPermission permission) {
    return _gateway.request(permission);
  }

  String rationale(AppPermission permission) {
    switch (permission) {
      case AppPermission.locationAlways:
        return '入退室の自動検知に常時位置情報を利用します。GPSで利用者や職員を追跡しない設計です。';
      case AppPermission.notifications:
        return '危険時の強通知を受け取るため通知権限が必要です。';
      case AppPermission.bluetoothScan:
        return 'Beacon検知で居室を特定するためBluetooth権限が必要です。';
    }
  }
}

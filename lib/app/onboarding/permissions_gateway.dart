enum AppPermission {
  locationAlways,
  notifications,
  bluetoothScan,
}

enum PermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

abstract class PermissionsGateway {
  Future<PermissionState> getStatus(AppPermission permission);

  Future<PermissionState> request(AppPermission permission);
}

import 'package:permission_handler/permission_handler.dart';

import 'permissions_gateway.dart';

enum PermissionStatusValue {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
}

class PermissionHandlerGateway implements PermissionsGateway {
  PermissionHandlerGateway();

  @override
  Future<PermissionState> getStatus(AppPermission permission) async {
    final status = await _resolve(permission).status;
    return mapStatus(status);
  }

  @override
  Future<PermissionState> request(AppPermission permission) async {
    final status = await _resolve(permission).request();
    return mapStatus(status);
  }

  static PermissionState mapStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return PermissionState.granted;
      case PermissionStatus.permanentlyDenied:
        return PermissionState.permanentlyDenied;
      case PermissionStatus.restricted:
        return PermissionState.restricted;
      case PermissionStatus.denied:
        return PermissionState.denied;
    }
  }

  static PermissionState mapStatusValue(PermissionStatusValue status) {
    switch (status) {
      case PermissionStatusValue.granted:
      case PermissionStatusValue.limited:
      case PermissionStatusValue.provisional:
        return PermissionState.granted;
      case PermissionStatusValue.permanentlyDenied:
        return PermissionState.permanentlyDenied;
      case PermissionStatusValue.restricted:
        return PermissionState.restricted;
      case PermissionStatusValue.denied:
        return PermissionState.denied;
    }
  }

  Permission _resolve(AppPermission permission) {
    switch (permission) {
      case AppPermission.locationAlways:
        return Permission.locationAlways;
      case AppPermission.notifications:
        return Permission.notification;
      case AppPermission.bluetoothScan:
        return Permission.bluetoothScan;
    }
  }
}

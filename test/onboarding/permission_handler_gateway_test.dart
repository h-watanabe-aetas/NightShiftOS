import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

void main() {
  test('locationAlways は PermissionState へ正しくマップされる', () {
    expect(
      PermissionHandlerGateway.mapStatusValue(PermissionStatusValue.granted),
      PermissionState.granted,
    );
    expect(
      PermissionHandlerGateway.mapStatusValue(PermissionStatusValue.permanentlyDenied),
      PermissionState.permanentlyDenied,
    );
  });
}

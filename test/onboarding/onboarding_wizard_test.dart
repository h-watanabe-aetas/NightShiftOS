import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class FakePermissionsGateway implements PermissionsGateway {
  FakePermissionsGateway(this.statuses);

  final Map<AppPermission, PermissionState> statuses;

  @override
  Future<PermissionState> getStatus(AppPermission permission) async {
    return statuses[permission] ?? PermissionState.denied;
  }

  @override
  Future<PermissionState> request(AppPermission permission) async {
    return statuses[permission] ?? PermissionState.denied;
  }
}

void main() {
  test('未許可権限を導線順に返す（位置情報常時 -> 通知 -> Bluetooth）', () async {
    final wizard = OnboardingWizard(
      gateway: FakePermissionsGateway({
        AppPermission.locationAlways: PermissionState.granted,
        AppPermission.notifications: PermissionState.denied,
        AppPermission.bluetoothScan: PermissionState.denied,
      }),
    );

    final pending = await wizard.pendingPermissions();

    expect(
      pending,
      [AppPermission.notifications, AppPermission.bluetoothScan],
    );
  });

  test('3権限が許可されるまで完了不可', () async {
    final wizard = OnboardingWizard(
      gateway: FakePermissionsGateway({
        AppPermission.locationAlways: PermissionState.granted,
        AppPermission.notifications: PermissionState.granted,
        AppPermission.bluetoothScan: PermissionState.denied,
      }),
    );

    expect(await wizard.canFinish(), isFalse);
  });

  test('GPSを追跡しない説明文を返す', () {
    final wizard = OnboardingWizard(
      gateway: FakePermissionsGateway({}),
    );

    final copy = wizard.rationale(AppPermission.locationAlways);

    expect(copy, contains('GPS'));
    expect(copy, contains('追跡しない'));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    statuses[permission] = PermissionState.granted;
    return PermissionState.granted;
  }
}

void main() {
  testWidgets('未許可権限がある場合は導線と説明文を表示する', (tester) async {
    final gateway = FakePermissionsGateway({
      AppPermission.locationAlways: PermissionState.granted,
      AppPermission.notifications: PermissionState.denied,
      AppPermission.bluetoothScan: PermissionState.denied,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsGatewayProvider.overrideWithValue(gateway),
        ],
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('GPS'), findsOneWidget);
    expect(find.text('通知権限を許可'), findsOneWidget);
    expect(find.text('Bluetooth権限を許可'), findsOneWidget);
    expect(find.byKey(const Key('complete-onboarding')), findsOneWidget);
  });

  testWidgets('全権限許可時は業務開始ボタンが有効', (tester) async {
    final gateway = FakePermissionsGateway({
      AppPermission.locationAlways: PermissionState.granted,
      AppPermission.notifications: PermissionState.granted,
      AppPermission.bluetoothScan: PermissionState.granted,
    });

    var completed = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsGatewayProvider.overrideWithValue(gateway),
        ],
        child: MaterialApp(
          home: OnboardingScreen(
            onCompleted: () {
              completed = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(find.byKey(const Key('complete-onboarding')));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('complete-onboarding')));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
  });
}

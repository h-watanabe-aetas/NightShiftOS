import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

void main() {
  test('alertNavigationProviderは通知minorを現在地と遷移要求に反映する', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final navigation = container.read(alertNavigationProvider);
    await navigation.openRoom(
      const CriticalAlert(
        roomLabel: '201号室',
        minor: 201,
        receivedAt: '2026-02-11T05:00:00.000Z',
      ),
    );

    expect(container.read(currentMinorProvider), 201);
    expect(container.read(pendingAlertMinorProvider), 201);
  });
}

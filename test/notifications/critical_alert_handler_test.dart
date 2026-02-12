import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class FakeNotifier implements CriticalAlertNotifier {
  int playAlarmCalls = 0;
  int vibrateCalls = 0;
  bool usedSystemNotification = false;
  DateTime shownAt = DateTime.parse('2026-02-11T03:00:01.500Z');

  @override
  Future<void> playAlarm() async {
    playAlarmCalls += 1;
  }

  @override
  Future<DateTime> showCritical(
    CriticalAlert alert, {
    required bool useSystemNotification,
  }) async {
    usedSystemNotification = useSystemNotification;
    return shownAt;
  }

  @override
  Future<void> vibrate() async {
    vibrateCalls += 1;
  }
}

class FakeNavigation implements AlertNavigation {
  int openRoomCalls = 0;

  @override
  Future<void> openRoom(CriticalAlert alert) async {
    openRoomCalls += 1;
  }
}

void main() {
  test('Foreground通知はオーバーレイ表示 + 音 + バイブ + 画面誘導を行う', () async {
    final notifier = FakeNotifier();
    final navigation = FakeNavigation();
    final handler = CriticalAlertHandler(
      notifier: notifier,
      navigation: navigation,
    );

    final result = await handler.handle(
      const CriticalAlert(
        roomLabel: '201号室',
        minor: 201,
        receivedAt: '2026-02-11T03:00:00.000Z',
      ),
      appState: AlertAppState.foreground,
    );

    expect(notifier.usedSystemNotification, isFalse);
    expect(notifier.playAlarmCalls, 1);
    expect(notifier.vibrateCalls, 1);
    expect(navigation.openRoomCalls, 1);
    expect(result.meetsP95Target, isTrue);
  });

  test('Background通知はシステム通知経由で表示する', () async {
    final notifier = FakeNotifier();
    final navigation = FakeNavigation();
    final handler = CriticalAlertHandler(
      notifier: notifier,
      navigation: navigation,
    );

    await handler.handle(
      const CriticalAlert(
        roomLabel: '202号室',
        minor: 202,
        receivedAt: '2026-02-11T03:00:00.000Z',
      ),
      appState: AlertAppState.background,
    );

    expect(notifier.usedSystemNotification, isTrue);
  });

  test('表示遅延が2秒超の場合はSLA未達判定になる', () async {
    final notifier = FakeNotifier()
      ..shownAt = DateTime.parse('2026-02-11T03:00:02.200Z');
    final navigation = FakeNavigation();
    final handler = CriticalAlertHandler(
      notifier: notifier,
      navigation: navigation,
    );

    final result = await handler.handle(
      const CriticalAlert(
        roomLabel: '203号室',
        minor: 203,
        receivedAt: '2026-02-11T03:00:00.000Z',
      ),
      appState: AlertAppState.foreground,
    );

    expect(result.meetsP95Target, isFalse);
    expect(result.latency, const Duration(milliseconds: 2200));
  });
}

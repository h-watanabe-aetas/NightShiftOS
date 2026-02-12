import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class SpyCriticalAlertHandler extends CriticalAlertHandler {
  SpyCriticalAlertHandler()
      : super(
          notifier: _NoopNotifier(),
          navigation: _NoopNavigation(),
        );

  CriticalAlert? capturedAlert;
  AlertAppState? capturedState;

  @override
  Future<CriticalAlertResult> handle(
    CriticalAlert alert, {
    required AlertAppState appState,
  }) async {
    capturedAlert = alert;
    capturedState = appState;
    return const CriticalAlertResult(
      latency: Duration(milliseconds: 500),
      meetsP95Target: true,
    );
  }
}

class _NoopNotifier implements CriticalAlertNotifier {
  @override
  Future<void> playAlarm() async {}

  @override
  Future<DateTime> showCritical(CriticalAlert alert, {required bool useSystemNotification}) async {
    return DateTime.parse('2026-02-11T03:00:01.000Z');
  }

  @override
  Future<void> vibrate() async {}
}

class _NoopNavigation implements AlertNavigation {
  @override
  Future<void> openRoom(CriticalAlert alert) async {}
}

void main() {
  test('FCM data payload を CriticalAlert に変換して handler へ渡す', () async {
    final spy = SpyCriticalAlertHandler();
    final dispatcher = FcmCriticalAlertDispatcher(handler: spy);

    final result = await dispatcher.dispatch(
      data: const {
        'room_label': '201号室',
        'minor': '201',
        'received_at': '2026-02-11T03:00:00.000Z',
      },
      appState: AlertAppState.foreground,
    );

    expect(result, isNotNull);
    expect(spy.capturedAlert?.roomLabel, '201号室');
    expect(spy.capturedAlert?.minor, 201);
    expect(spy.capturedState, AlertAppState.foreground);
  });

  test('必須データ欠落時は null を返し handler を呼ばない', () async {
    final spy = SpyCriticalAlertHandler();
    final dispatcher = FcmCriticalAlertDispatcher(handler: spy);

    final result = await dispatcher.dispatch(
      data: const {
        'minor': '201',
      },
      appState: AlertAppState.foreground,
    );

    expect(result, isNull);
    expect(spy.capturedAlert, isNull);
  });
}

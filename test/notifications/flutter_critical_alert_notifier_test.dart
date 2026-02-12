import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class SpyLocalNotificationGateway implements LocalNotificationGateway {
  bool lastUseSystemNotification = false;
  String? lastTitle;
  String? lastBody;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required bool useSystemNotification,
  }) async {
    lastUseSystemNotification = useSystemNotification;
    lastTitle = title;
    lastBody = body;
  }
}

class SpyFeedback implements AlertFeedback {
  int alarmCalls = 0;
  int vibrateCalls = 0;

  @override
  Future<void> alarm() async {
    alarmCalls += 1;
  }

  @override
  Future<void> vibrate() async {
    vibrateCalls += 1;
  }
}

void main() {
  test('showCritical は room 情報を通知本文へ渡す', () async {
    final gateway = SpyLocalNotificationGateway();
    final feedback = SpyFeedback();
    final notifier = FlutterCriticalAlertNotifier(
      gateway: gateway,
      feedback: feedback,
      now: () => DateTime.parse('2026-02-11T03:00:01.000Z'),
    );

    final shownAt = await notifier.showCritical(
      const CriticalAlert(
        roomLabel: '201号室',
        minor: 201,
        receivedAt: '2026-02-11T03:00:00.000Z',
      ),
      useSystemNotification: true,
    );

    expect(gateway.lastUseSystemNotification, isTrue);
    expect(gateway.lastTitle, contains('危険アラート'));
    expect(gateway.lastBody, contains('201号室'));
    expect(shownAt, DateTime.parse('2026-02-11T03:00:01.000Z'));
  });

  test('playAlarm / vibrate はフィードバックへ委譲する', () async {
    final gateway = SpyLocalNotificationGateway();
    final feedback = SpyFeedback();
    final notifier = FlutterCriticalAlertNotifier(
      gateway: gateway,
      feedback: feedback,
      now: DateTime.now,
    );

    await notifier.playAlarm();
    await notifier.vibrate();

    expect(feedback.alarmCalls, 1);
    expect(feedback.vibrateCalls, 1);
  });
}

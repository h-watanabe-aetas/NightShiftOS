import 'alert_feedback.dart';
import 'critical_alert.dart';
import 'critical_alert_notifier.dart';
import 'local_notification_gateway.dart';

class FlutterCriticalAlertNotifier implements CriticalAlertNotifier {
  FlutterCriticalAlertNotifier({
    required LocalNotificationGateway gateway,
    required AlertFeedback feedback,
    required DateTime Function() now,
  })  : _gateway = gateway,
        _feedback = feedback,
        _now = now;

  final LocalNotificationGateway _gateway;
  final AlertFeedback _feedback;
  final DateTime Function() _now;

  @override
  Future<void> playAlarm() {
    return _feedback.alarm();
  }

  @override
  Future<DateTime> showCritical(
    CriticalAlert alert, {
    required bool useSystemNotification,
  }) async {
    await _gateway.show(
      id: alert.minor ?? 0,
      title: '危険アラート',
      body: '${alert.roomLabel}で危険予兆を検知しました',
      useSystemNotification: useSystemNotification,
    );
    return _now().toUtc();
  }

  @override
  Future<void> vibrate() {
    return _feedback.vibrate();
  }
}

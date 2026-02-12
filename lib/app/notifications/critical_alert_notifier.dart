import 'critical_alert.dart';

abstract class CriticalAlertNotifier {
  Future<DateTime> showCritical(
    CriticalAlert alert, {
    required bool useSystemNotification,
  });

  Future<void> playAlarm();

  Future<void> vibrate();
}

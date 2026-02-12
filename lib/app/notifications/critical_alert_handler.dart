import 'alert_navigation.dart';
import 'critical_alert.dart';
import 'critical_alert_notifier.dart';

enum AlertAppState {
  foreground,
  background,
  terminated,
}

class CriticalAlertResult {
  const CriticalAlertResult({
    required this.latency,
    required this.meetsP95Target,
  });

  final Duration latency;
  final bool meetsP95Target;
}

class CriticalAlertHandler {
  CriticalAlertHandler({
    required CriticalAlertNotifier notifier,
    required AlertNavigation navigation,
  })  : _notifier = notifier,
        _navigation = navigation;

  final CriticalAlertNotifier _notifier;
  final AlertNavigation _navigation;

  Future<CriticalAlertResult> handle(
    CriticalAlert alert, {
    required AlertAppState appState,
  }) async {
    final shownAt = await _notifier.showCritical(
      alert,
      useSystemNotification: appState != AlertAppState.foreground,
    );

    if (appState == AlertAppState.foreground) {
      await _notifier.playAlarm();
      await _notifier.vibrate();
    }

    await _navigation.openRoom(alert);

    final receivedAt = DateTime.parse(alert.receivedAt).toUtc();
    final latency = shownAt.toUtc().difference(receivedAt);
    return CriticalAlertResult(
      latency: latency,
      meetsP95Target: latency <= const Duration(seconds: 2),
    );
  }
}

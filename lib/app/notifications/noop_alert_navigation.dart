import 'alert_navigation.dart';
import 'critical_alert.dart';

class NoopAlertNavigation implements AlertNavigation {
  @override
  Future<void> openRoom(CriticalAlert alert) async {}
}

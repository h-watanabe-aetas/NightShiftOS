import 'critical_alert.dart';

abstract class AlertNavigation {
  Future<void> openRoom(CriticalAlert alert);
}

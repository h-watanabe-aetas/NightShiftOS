import 'alert_navigation.dart';
import 'critical_alert.dart';

typedef MinorSetter = void Function(int minor);

class ProviderAlertNavigation implements AlertNavigation {
  ProviderAlertNavigation({
    required MinorSetter setCurrentMinor,
    required MinorSetter requestDashboardNavigation,
  })  : _setCurrentMinor = setCurrentMinor,
        _requestDashboardNavigation = requestDashboardNavigation;

  final MinorSetter _setCurrentMinor;
  final MinorSetter _requestDashboardNavigation;

  @override
  Future<void> openRoom(CriticalAlert alert) async {
    final minor = alert.minor;
    if (minor == null) {
      return;
    }

    _setCurrentMinor(minor);
    _requestDashboardNavigation(minor);
  }
}

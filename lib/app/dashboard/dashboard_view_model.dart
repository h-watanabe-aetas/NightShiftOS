import '../care/care_action.dart';

class DashboardViewModel {
  const DashboardViewModel({
    required this.staffName,
    required this.facilityName,
    required this.currentMinor,
    required this.isMonitoring,
    required this.unsyncedCount,
  });

  final String staffName;
  final String facilityName;
  final int? currentMinor;
  final bool isMonitoring;
  final int unsyncedCount;

  String get locationLabel {
    if (currentMinor == null) {
      return '移動中...';
    }
    return '$currentMinor号室';
  }

  String get monitoringLabel => isMonitoring ? '監視中' : '停止中';

  String get queueLabel => '未送信 $unsyncedCount件';

  bool get shouldHighlightQueue => unsyncedCount > 0;

  List<CareAction> get quickActions => const [
        CareAction.toilet,
        CareAction.posture,
        CareAction.check,
        CareAction.transfer,
        CareAction.hydration,
        CareAction.other,
      ];
}

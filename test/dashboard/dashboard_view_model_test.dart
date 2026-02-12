import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

void main() {
  test('minorがある場合は 号室表示', () {
    const vm = DashboardViewModel(
      staffName: 'Sato',
      facilityName: 'Aetas Home',
      currentMinor: 201,
      isMonitoring: true,
      unsyncedCount: 0,
    );

    expect(vm.locationLabel, '201号室');
    expect(vm.monitoringLabel, '監視中');
  });

  test('minorが無い場合は 移動中 表示', () {
    const vm = DashboardViewModel(
      staffName: 'Sato',
      facilityName: 'Aetas Home',
      currentMinor: null,
      isMonitoring: true,
      unsyncedCount: 0,
    );

    expect(vm.locationLabel, '移動中...');
  });

  test('未送信件数を表示し、件数>0なら警告表示を有効化', () {
    const vm = DashboardViewModel(
      staffName: 'Sato',
      facilityName: 'Aetas Home',
      currentMinor: 201,
      isMonitoring: true,
      unsyncedCount: 3,
    );

    expect(vm.queueLabel, '未送信 3件');
    expect(vm.shouldHighlightQueue, isTrue);
  });

  test('クイックアクションは3x2想定の6個を返す', () {
    const vm = DashboardViewModel(
      staffName: 'Sato',
      facilityName: 'Aetas Home',
      currentMinor: 201,
      isMonitoring: true,
      unsyncedCount: 0,
    );

    expect(vm.quickActions.length, 6);
    expect(vm.quickActions.first, CareAction.toilet);
  });
}

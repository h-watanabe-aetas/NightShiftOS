import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

void main() {
  test('facility_id 取得前は監視開始不可', () {
    const state = AuthState(staffId: 'staff-1', facilityId: null);
    expect(state.canStartMonitoring(), isFalse);
  });

  test('staff_id と facility_id が揃えば監視開始可能', () {
    const state = AuthState(staffId: 'staff-1', facilityId: 12);
    expect(state.canStartMonitoring(), isTrue);
  });
}

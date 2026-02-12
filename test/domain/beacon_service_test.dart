import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

void main() {
  test('facility_id 取得前は startMonitoring できない', () {
    final service = BeaconService(idGenerator: () => 'id-1');
    const authState = AuthState(staffId: 'staff-1');

    expect(
      () => service.startMonitoring(authState),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('facility_id'),
        ),
      ),
    );
  });

  test('RSSI > -90 の範囲で最も強い minor を採用する', () {
    final minor = BeaconService.pickMinor(const [
      BeaconReading(minor: 201, rssi: -70),
      BeaconReading(minor: 202, rssi: -65),
      BeaconReading(minor: 203, rssi: -91),
    ]);

    expect(minor, 202);
  });

  test('閾値を満たす beacon がなければ minor は null', () {
    final minor = BeaconService.pickMinor(const [
      BeaconReading(minor: 201, rssi: -95),
      BeaconReading(minor: 202, rssi: -100),
    ]);

    expect(minor, isNull);
  });

  test('enter で ENTER ログを生成し、minor にranging結果を反映する', () {
    final service = BeaconService(idGenerator: () => 'id-enter');
    const authState = AuthState(staffId: 'staff-1', facilityId: 1);
    service.startMonitoring(authState);

    final event = service.handleEnterRegion(
      staffId: 'staff-1',
      timestamp: DateTime.parse('2026-02-11T01:23:45.000Z'),
      rangingReadings: const [
        BeaconReading(minor: 201, rssi: -77),
        BeaconReading(minor: 202, rssi: -72),
      ],
    );

    expect(event.id, 'id-enter');
    expect(event.action, 'ENTER');
    expect(event.minor, 202);
    expect(event.rssi, -72);
    expect(event.staffId, 'staff-1');
    expect(service.lastKnownMinor, 202);
  });

  test('exit で lastKnownMinor を使った EXIT ログを生成する', () {
    var sequence = 0;
    final service = BeaconService(idGenerator: () {
      sequence += 1;
      return 'id-$sequence';
    });
    const authState = AuthState(staffId: 'staff-1', facilityId: 1);
    service.startMonitoring(authState);
    service.handleEnterRegion(
      staffId: 'staff-1',
      timestamp: DateTime.parse('2026-02-11T01:23:45.000Z'),
      rangingReadings: const [BeaconReading(minor: 201, rssi: -70)],
    );

    final event = service.handleExitRegion(
      staffId: 'staff-1',
      timestamp: DateTime.parse('2026-02-11T01:24:45.000Z'),
    );

    expect(event.action, 'EXIT');
    expect(event.minor, 201);
  });

  test('stopMonitoringで監視停止し、lastKnownMinorをクリアする', () {
    final service = BeaconService(idGenerator: () => 'id-1');
    const authState = AuthState(staffId: 'staff-1', facilityId: 1);
    service.startMonitoring(authState);
    service.handleEnterRegion(
      staffId: 'staff-1',
      timestamp: DateTime.parse('2026-02-11T01:23:45.000Z'),
      rangingReadings: const [BeaconReading(minor: 201, rssi: -70)],
    );

    service.stopMonitoring();

    expect(service.isMonitoring, isFalse);
    expect(service.lastKnownMinor, isNull);
    expect(
      () => service.handleEnterRegion(
        staffId: 'staff-1',
        timestamp: DateTime.parse('2026-02-11T01:23:46.000Z'),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('updateLastKnownMinorはnull以外を最終minorとして保持する', () {
    final service = BeaconService(idGenerator: () => 'id-1');

    service.updateLastKnownMinor(201);
    service.updateLastKnownMinor(null);

    expect(service.lastKnownMinor, 201);
  });
}

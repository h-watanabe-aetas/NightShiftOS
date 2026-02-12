import 'dart:async';

import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class FakeBeaconMonitoringGateway implements BeaconMonitoringGateway {
  bool initialized = false;
  List<Region>? regions;
  final StreamController<MonitoringResult> controller = StreamController();

  @override
  Future<bool> initializeAndCheckScanning() async {
    initialized = true;
    return true;
  }

  @override
  Stream<MonitoringResult> monitoring(List<Region> regions) {
    this.regions = regions;
    return controller.stream;
  }
}

void main() {
  test('didEnter/didExitをBeaconMonitoringEventへ変換する', () async {
    final gateway = FakeBeaconMonitoringGateway();
    final source = FlutterBeaconMonitoringSource(gateway: gateway);
    addTearDown(gateway.controller.close);

    final values = <BeaconMonitoringEvent>[];
    final subscription =
        source.watchMonitoring(facilityId: 1).listen(values.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    gateway.controller.add(
      MonitoringResult.from({
        'event': 'didEnterRegion',
        'region': {
          'identifier': 'nightshift-facility-1',
          'proximityUUID': defaultBeaconProximityUuid,
          'major': 1,
        },
      }),
    );
    gateway.controller.add(
      MonitoringResult.from({
        'event': 'didExitRegion',
        'region': {
          'identifier': 'nightshift-facility-1',
          'proximityUUID': defaultBeaconProximityUuid,
          'major': 1,
        },
      }),
    );
    gateway.controller.add(
      MonitoringResult.from({
        'event': 'didDetermineStateForRegion',
        'state': 'inside',
        'region': {
          'identifier': 'nightshift-facility-1',
          'proximityUUID': defaultBeaconProximityUuid,
          'major': 1,
        },
      }),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(values.length, 2);
    expect(values[0].type, BeaconMonitoringEventType.enter);
    expect(values[1].type, BeaconMonitoringEventType.exit);
  });

  test('watchMonitoring開始時にfacility majorでregionを設定する', () async {
    final gateway = FakeBeaconMonitoringGateway();
    final source = FlutterBeaconMonitoringSource(gateway: gateway);
    addTearDown(gateway.controller.close);

    final subscription = source.watchMonitoring(facilityId: 7).listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(gateway.initialized, isTrue);
    expect(gateway.regions, isNotNull);
    expect(gateway.regions!.length, 1);
    expect(gateway.regions!.first.major, 7);
    expect(gateway.regions!.first.proximityUUID, defaultBeaconProximityUuid);
    await subscription.cancel();
  });
}

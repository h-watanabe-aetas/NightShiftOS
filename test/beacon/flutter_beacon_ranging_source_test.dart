import 'dart:async';

import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class FakeBeaconRangingGateway implements BeaconRangingGateway {
  bool canScan = true;
  bool initialized = false;
  List<Region>? regions;
  final StreamController<RangingResult> controller = StreamController();

  @override
  Future<bool> initializeAndCheckScanning() async {
    initialized = true;
    return canScan;
  }

  @override
  Stream<RangingResult> ranging(List<Region> regions) {
    this.regions = regions;
    return controller.stream;
  }
}

void main() {
  test('watchRangingはfacility majorのbeaconをBeaconReadingへ変換する', () async {
    final gateway = FakeBeaconRangingGateway();
    final source = FlutterBeaconRangingSource(gateway: gateway);
    addTearDown(gateway.controller.close);

    final firstResult = source.watchRanging(facilityId: 1).first;
    await Future<void>.delayed(const Duration(milliseconds: 20));

    gateway.controller.add(
      RangingResult.from({
        'region': {
          'identifier': 'nightshift-facility-1',
          'proximityUUID': defaultBeaconProximityUuid,
          'major': 1,
        },
        'beacons': [
          {
            'proximityUUID': defaultBeaconProximityUuid,
            'major': 1,
            'minor': 201,
            'rssi': -71,
            'accuracy': 0.9,
          },
          {
            'proximityUUID': defaultBeaconProximityUuid,
            'major': 2,
            'minor': 999,
            'rssi': -50,
            'accuracy': 0.6,
          },
        ],
      }),
    );

    final readings = await firstResult;
    expect(readings.length, 1);
    expect(readings.first.minor, 201);
    expect(readings.first.rssi, -71);
  });

  test('watchRanging開始時にfacility majorでregionを設定する', () async {
    final gateway = FakeBeaconRangingGateway();
    final source = FlutterBeaconRangingSource(gateway: gateway);
    addTearDown(gateway.controller.close);

    final subscription = source.watchRanging(facilityId: 7).listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(gateway.initialized, isTrue);
    expect(gateway.regions, isNotNull);
    expect(gateway.regions!.length, 1);
    expect(gateway.regions!.first.major, 7);
    expect(gateway.regions!.first.proximityUUID, defaultBeaconProximityUuid);
    await subscription.cancel();
  });
}

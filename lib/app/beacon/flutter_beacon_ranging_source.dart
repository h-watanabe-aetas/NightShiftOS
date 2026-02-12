import 'package:flutter_beacon/flutter_beacon.dart';
import 'dart:async';

import '../domain/beacon_reading.dart';
import 'beacon_ranging_source.dart';

const String defaultBeaconProximityUuid =
    '4fafc201-1fb5-459e-8fcc-c5c9c331914b';

abstract class BeaconRangingGateway {
  Future<bool> initializeAndCheckScanning();

  Stream<RangingResult> ranging(List<Region> regions);
}

class FlutterBeaconRangingGateway implements BeaconRangingGateway {
  const FlutterBeaconRangingGateway();

  @override
  Future<bool> initializeAndCheckScanning() {
    return flutterBeacon.initializeAndCheckScanning;
  }

  @override
  Stream<RangingResult> ranging(List<Region> regions) {
    return flutterBeacon.ranging(regions);
  }
}

class FlutterBeaconRangingSource implements BeaconRangingSource {
  FlutterBeaconRangingSource({
    BeaconRangingGateway? gateway,
    this.proximityUuid = defaultBeaconProximityUuid,
  }) : _gateway = gateway ?? const FlutterBeaconRangingGateway();

  final BeaconRangingGateway _gateway;
  final String proximityUuid;

  @override
  Stream<List<BeaconReading>> watchRanging({required int facilityId}) {
    StreamSubscription<RangingResult>? rangingSubscription;
    late final StreamController<List<BeaconReading>> controller;

    controller = StreamController<List<BeaconReading>>(
      onListen: () async {
        final initialized = await _gateway.initializeAndCheckScanning();
        if (!initialized) {
          await controller.close();
          return;
        }

        final region = Region(
          identifier: 'nightshift-facility-$facilityId',
          proximityUUID: proximityUuid,
          major: facilityId,
        );

        rangingSubscription = _gateway.ranging([region]).listen(
          (result) {
            final readings = result.beacons
                .where((beacon) => beacon.major == facilityId)
                .map(
                  (beacon) => BeaconReading(
                    minor: beacon.minor,
                    rssi: beacon.rssi,
                  ),
                )
                .toList(growable: false);
            if (!controller.isClosed) {
              controller.add(readings);
            }
          },
          onError: controller.addError,
          onDone: () {
            if (!controller.isClosed) {
              controller.close();
            }
          },
        );
      },
      onCancel: () async {
        await rangingSubscription?.cancel();
      },
    );

    return controller.stream;
  }
}

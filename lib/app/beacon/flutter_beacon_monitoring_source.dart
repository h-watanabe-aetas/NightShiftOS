import 'dart:async';

import 'package:flutter_beacon/flutter_beacon.dart';

import 'beacon_monitoring_source.dart';
import 'flutter_beacon_ranging_source.dart';

abstract class BeaconMonitoringGateway {
  Future<bool> initializeAndCheckScanning();

  Stream<MonitoringResult> monitoring(List<Region> regions);
}

class FlutterBeaconMonitoringGateway implements BeaconMonitoringGateway {
  const FlutterBeaconMonitoringGateway();

  @override
  Future<bool> initializeAndCheckScanning() {
    return flutterBeacon.initializeAndCheckScanning;
  }

  @override
  Stream<MonitoringResult> monitoring(List<Region> regions) {
    return flutterBeacon.monitoring(regions);
  }
}

class FlutterBeaconMonitoringSource implements BeaconMonitoringSource {
  FlutterBeaconMonitoringSource({
    BeaconMonitoringGateway? gateway,
    this.proximityUuid = defaultBeaconProximityUuid,
  }) : _gateway = gateway ?? const FlutterBeaconMonitoringGateway();

  final BeaconMonitoringGateway _gateway;
  final String proximityUuid;

  @override
  Stream<BeaconMonitoringEvent> watchMonitoring({required int facilityId}) {
    StreamSubscription<MonitoringResult>? monitoringSubscription;
    late final StreamController<BeaconMonitoringEvent> controller;

    controller = StreamController<BeaconMonitoringEvent>(
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

        monitoringSubscription = _gateway.monitoring([region]).listen(
          (result) {
            final major = result.region.major;
            if (major != facilityId) {
              return;
            }

            final type = _toEventType(result.monitoringEventType);
            if (type == null || controller.isClosed) {
              return;
            }
            controller.add(
              BeaconMonitoringEvent(type: type, facilityId: facilityId),
            );
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
        await monitoringSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  BeaconMonitoringEventType? _toEventType(MonitoringEventType type) {
    switch (type) {
      case MonitoringEventType.didEnterRegion:
        return BeaconMonitoringEventType.enter;
      case MonitoringEventType.didExitRegion:
        return BeaconMonitoringEventType.exit;
      case MonitoringEventType.didDetermineStateForRegion:
        return null;
    }
  }
}

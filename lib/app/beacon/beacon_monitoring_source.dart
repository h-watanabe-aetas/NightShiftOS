enum BeaconMonitoringEventType {
  enter,
  exit,
}

class BeaconMonitoringEvent {
  const BeaconMonitoringEvent({
    required this.type,
    required this.facilityId,
  });

  final BeaconMonitoringEventType type;
  final int facilityId;
}

abstract class BeaconMonitoringSource {
  Stream<BeaconMonitoringEvent> watchMonitoring({
    required int facilityId,
  });
}

class NoopBeaconMonitoringSource implements BeaconMonitoringSource {
  const NoopBeaconMonitoringSource();

  @override
  Stream<BeaconMonitoringEvent> watchMonitoring({required int facilityId}) {
    return const Stream.empty();
  }
}

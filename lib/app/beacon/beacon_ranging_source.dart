import '../domain/beacon_reading.dart';

abstract class BeaconRangingSource {
  Stream<List<BeaconReading>> watchRanging({
    required int facilityId,
  });
}

class NoopBeaconRangingSource implements BeaconRangingSource {
  const NoopBeaconRangingSource();

  @override
  Stream<List<BeaconReading>> watchRanging({required int facilityId}) {
    return const Stream.empty();
  }
}

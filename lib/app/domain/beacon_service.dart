import 'auth_state.dart';
import 'beacon_reading.dart';
import 'movement_log.dart';
import 'uuid_v7.dart';

typedef BeaconIdGenerator = String Function();

class BeaconService {
  BeaconService({BeaconIdGenerator? idGenerator})
      : _idGenerator = idGenerator ?? createUuidV7;

  final BeaconIdGenerator _idGenerator;

  bool _isMonitoring = false;
  int? _facilityId;
  int? _lastKnownMinor;

  bool get isMonitoring => _isMonitoring;
  int? get facilityId => _facilityId;
  int? get lastKnownMinor => _lastKnownMinor;

  void startMonitoring(AuthState authState) {
    if (!authState.canStartMonitoring()) {
      throw StateError('facility_id must be resolved before monitoring starts');
    }
    _isMonitoring = true;
    _facilityId = authState.facilityId;
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _lastKnownMinor = null;
  }

  void updateLastKnownMinor(int? minor) {
    if (minor != null) {
      _lastKnownMinor = minor;
    }
  }

  static BeaconReading? pickBestReading(List<BeaconReading> rangingReadings) {
    final candidates =
        rangingReadings.where((reading) => reading.rssi > -90).toList();
    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort((left, right) => right.rssi.compareTo(left.rssi));
    return candidates.first;
  }

  static int? pickMinor(List<BeaconReading> rangingReadings) {
    return pickBestReading(rangingReadings)?.minor;
  }

  MovementLog handleEnterRegion({
    required String staffId,
    required DateTime timestamp,
    List<BeaconReading> rangingReadings = const [],
  }) {
    _assertMonitoring();
    final bestReading = pickBestReading(rangingReadings);
    final minor = bestReading?.minor ?? _lastKnownMinor;

    if (minor != null) {
      _lastKnownMinor = minor;
    }

    return MovementLog(
      id: _idGenerator(),
      staffId: staffId,
      minor: minor,
      action: 'ENTER',
      timestamp: timestamp,
      rssi: bestReading?.rssi,
    );
  }

  MovementLog handleExitRegion({
    required String staffId,
    required DateTime timestamp,
  }) {
    _assertMonitoring();
    return MovementLog(
      id: _idGenerator(),
      staffId: staffId,
      minor: _lastKnownMinor,
      action: 'EXIT',
      timestamp: timestamp,
      rssi: null,
    );
  }

  void _assertMonitoring() {
    if (!_isMonitoring) {
      throw StateError('monitoring is not active');
    }
  }
}

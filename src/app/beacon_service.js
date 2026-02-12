const { createUuidV7 } = require('./uuid_v7');

class BeaconService {
  constructor({ idGenerator = createUuidV7 } = {}) {
    this.idGenerator = idGenerator;
    this.monitoring = false;
    this.facilityId = null;
    this.lastKnownMinor = null;
  }

  startMonitoring(authState) {
    if (!authState || !authState.canStartMonitoring()) {
      throw new Error('facility_id must be resolved before monitoring starts');
    }

    this.monitoring = true;
    this.facilityId = authState.facilityId;
  }

  static pickBestReading(rangingReadings = []) {
    const candidates = rangingReadings
      .filter((reading) => Number.isInteger(reading.minor))
      .filter((reading) => typeof reading.rssi === 'number' && reading.rssi > -90)
      .sort((left, right) => right.rssi - left.rssi);

    return candidates[0] ?? null;
  }

  static pickMinor(rangingReadings = []) {
    return BeaconService.pickBestReading(rangingReadings)?.minor ?? null;
  }

  _assertMonitoring() {
    if (!this.monitoring) {
      throw new Error('monitoring is not active');
    }
  }

  _createMovement({ staffId, action, minor, timestamp, rssi = null }) {
    return {
      id: this.idGenerator(),
      staffId,
      minor,
      action,
      timestamp,
      rssi
    };
  }

  handleEnterRegion({ staffId, timestamp, rangingReadings = [] }) {
    this._assertMonitoring();

    const bestReading = BeaconService.pickBestReading(rangingReadings);
    const minor = bestReading?.minor ?? this.lastKnownMinor;
    const rssi = bestReading?.rssi ?? null;

    if (Number.isInteger(minor)) {
      this.lastKnownMinor = minor;
    }

    return this._createMovement({
      staffId,
      action: 'ENTER',
      minor,
      timestamp,
      rssi
    });
  }

  handleExitRegion({ staffId, timestamp }) {
    this._assertMonitoring();

    return this._createMovement({
      staffId,
      action: 'EXIT',
      minor: this.lastKnownMinor,
      timestamp,
      rssi: null
    });
  }
}

module.exports = {
  BeaconService
};

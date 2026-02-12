const test = require('node:test');
const assert = require('node:assert/strict');

const { AuthState } = require('../src/app/auth_state');
const { BeaconService } = require('../src/app/beacon_service');

test('BeaconService: facility_id 取得前は startMonitoring できない', () => {
  const beaconService = new BeaconService();
  const authState = new AuthState({ staffId: 'staff-1', facilityId: null });

  assert.throws(() => {
    beaconService.startMonitoring(authState);
  }, /facility_id/);
});

test('BeaconService: RSSI > -90 の範囲で最も強い minor を採用する', () => {
  const picked = BeaconService.pickMinor([
    { minor: 201, rssi: -70 },
    { minor: 202, rssi: -65 },
    { minor: 203, rssi: -91 }
  ]);

  assert.equal(picked, 202);
});

test('BeaconService: 閾値を満たす beacon がなければ minor は null', () => {
  const picked = BeaconService.pickMinor([
    { minor: 201, rssi: -95 },
    { minor: 202, rssi: -100 }
  ]);

  assert.equal(picked, null);
});

test('BeaconService: enter で ENTER ログを生成し、minor にranging結果を反映する', () => {
  const beaconService = new BeaconService();
  const authState = new AuthState({ staffId: 'staff-1', facilityId: 1 });
  beaconService.startMonitoring(authState);

  const event = beaconService.handleEnterRegion({
    staffId: 'staff-1',
    timestamp: '2026-02-11T01:23:45.000Z',
    rangingReadings: [
      { minor: 201, rssi: -77 },
      { minor: 202, rssi: -72 }
    ]
  });

  assert.equal(event.action, 'ENTER');
  assert.equal(event.minor, 202);
  assert.equal(event.rssi, -72);
  assert.equal(event.staffId, 'staff-1');
});

test('BeaconService: exit で lastKnownMinor を使った EXIT ログを生成する', () => {
  const beaconService = new BeaconService();
  const authState = new AuthState({ staffId: 'staff-1', facilityId: 1 });
  beaconService.startMonitoring(authState);

  beaconService.handleEnterRegion({
    staffId: 'staff-1',
    timestamp: '2026-02-11T01:23:45.000Z',
    rangingReadings: [{ minor: 201, rssi: -70 }]
  });

  const event = beaconService.handleExitRegion({
    staffId: 'staff-1',
    timestamp: '2026-02-11T01:24:45.000Z'
  });

  assert.equal(event.action, 'EXIT');
  assert.equal(event.minor, 201);
});

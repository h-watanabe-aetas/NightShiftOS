const test = require('node:test');
const assert = require('node:assert/strict');

const { AuthState } = require('../src/app/auth_state');

test('AuthState: facility_id 取得前は監視開始不可', () => {
  const state = new AuthState({ staffId: 'staff-1', facilityId: null });
  assert.equal(state.canStartMonitoring(), false);
});

test('AuthState: staff_id と facility_id が揃えば監視開始可能', () => {
  const state = new AuthState({ staffId: 'staff-1', facilityId: 12 });
  assert.equal(state.canStartMonitoring(), true);
});

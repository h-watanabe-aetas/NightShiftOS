class AuthState {
  constructor({ staffId = null, facilityId = null } = {}) {
    this.staffId = staffId;
    this.facilityId = facilityId;
  }

  canStartMonitoring() {
    return Boolean(this.staffId) && Number.isInteger(this.facilityId);
  }
}

module.exports = {
  AuthState
};

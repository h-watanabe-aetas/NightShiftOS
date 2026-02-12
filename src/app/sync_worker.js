class SyncWorker {
  constructor({ queue }) {
    if (!queue || typeof queue.syncPending !== 'function') {
      throw new Error('queue.syncPending is required');
    }

    this.queue = queue;
  }

  async onNetworkRecovered() {
    return this.queue.syncPending({ trigger: 'network_recovered' });
  }

  async onAppLaunch() {
    return this.queue.syncPending({ trigger: 'app_launch' });
  }

  async onPeriodic() {
    return this.queue.syncPending({ trigger: 'periodic' });
  }
}

module.exports = {
  SyncWorker
};

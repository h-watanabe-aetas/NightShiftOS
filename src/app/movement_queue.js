class MovementQueue {
  constructor({ transport }) {
    if (!transport || typeof transport.send !== 'function') {
      throw new Error('transport.send is required');
    }

    this.transport = transport;
    this.logs = new Map();
  }

  totalCount() {
    return this.logs.size;
  }

  getById(id) {
    return this.logs.get(id) ?? null;
  }

  listUnsynced() {
    return Array.from(this.logs.values()).filter((item) => item.isSynced === false);
  }

  unsyncedCount() {
    return this.listUnsynced().length;
  }

  async enqueue(movement) {
    const existing = this.logs.get(movement.id);
    if (existing) {
      return existing;
    }

    const normalized = {
      ...movement,
      isSynced: movement.isSynced ?? false
    };
    this.logs.set(normalized.id, normalized);
    return normalized;
  }

  _markSynced(batch) {
    for (const item of batch) {
      const existing = this.logs.get(item.id);
      if (existing) {
        existing.isSynced = true;
      }
    }
  }

  async saveLog(movement) {
    const log = await this.enqueue(movement);

    if (log.isSynced) {
      return log;
    }

    try {
      await this.transport.send([log], {
        isOfflineSync: false,
        trigger: 'immediate'
      });
      log.isSynced = true;
    } catch (_error) {
      log.isSynced = false;
    }

    return log;
  }

  async syncPending({ trigger = 'manual' } = {}) {
    const pending = this.listUnsynced();
    if (pending.length === 0) {
      return 0;
    }

    try {
      await this.transport.send(pending, {
        isOfflineSync: true,
        trigger
      });
      this._markSynced(pending);
      return pending.length;
    } catch (_error) {
      return 0;
    }
  }
}

module.exports = {
  MovementQueue
};

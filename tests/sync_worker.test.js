const test = require('node:test');
const assert = require('node:assert/strict');

const { SyncWorker } = require('../src/app/sync_worker');

test('SyncWorker: 接続回復/起動時/定期実行の各トリガで syncPending を呼ぶ', async () => {
  const triggers = [];
  const queue = {
    async syncPending({ trigger }) {
      triggers.push(trigger);
      return 3;
    }
  };

  const worker = new SyncWorker({ queue });

  await worker.onNetworkRecovered();
  await worker.onAppLaunch();
  await worker.onPeriodic();

  assert.deepEqual(triggers, ['network_recovered', 'app_launch', 'periodic']);
});

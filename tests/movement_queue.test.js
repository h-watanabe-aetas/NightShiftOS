const test = require('node:test');
const assert = require('node:assert/strict');

const { MovementQueue } = require('../src/app/movement_queue');

function sampleMovement(overrides = {}) {
  return {
    id: overrides.id ?? '018f8f77-6f7a-7000-8000-000000000001',
    staffId: overrides.staffId ?? 'staff-1',
    minor: overrides.minor ?? 201,
    action: overrides.action ?? 'ENTER',
    timestamp: overrides.timestamp ?? '2026-02-11T02:00:00.000Z',
    rssi: overrides.rssi ?? -68
  };
}

test('MovementQueue: saveLog は送信失敗時でも先保存される（Store-and-Forward）', async () => {
  const sentCalls = [];
  const queue = new MovementQueue({
    transport: {
      async send(batch, options) {
        sentCalls.push({ batch, options });
        throw new Error('offline');
      }
    }
  });

  await queue.saveLog(sampleMovement());

  assert.equal(queue.unsyncedCount(), 1);
  assert.equal(sentCalls.length, 1);
  assert.equal(queue.getById('018f8f77-6f7a-7000-8000-000000000001').isSynced, false);
});

test('MovementQueue: saveLog は送信成功時に isSynced=true へ更新される', async () => {
  const queue = new MovementQueue({
    transport: {
      async send() {
        return { ok: true };
      }
    }
  });

  await queue.saveLog(sampleMovement());

  assert.equal(queue.unsyncedCount(), 0);
  assert.equal(queue.getById('018f8f77-6f7a-7000-8000-000000000001').isSynced, true);
});

test('MovementQueue: syncPending は未同期ログを一括送信し is_offline_sync=true を付与する', async () => {
  const sentCalls = [];
  const queue = new MovementQueue({
    transport: {
      async send(batch, options) {
        sentCalls.push({ batch, options });
        return { ok: true };
      }
    }
  });

  await queue.enqueue(sampleMovement({ id: '018f8f77-6f7a-7000-8000-000000000010' }));
  await queue.enqueue(sampleMovement({ id: '018f8f77-6f7a-7000-8000-000000000011', minor: 202 }));

  const syncedCount = await queue.syncPending({ trigger: 'network_recovered' });

  assert.equal(syncedCount, 2);
  assert.equal(queue.unsyncedCount(), 0);
  assert.equal(sentCalls.length, 1);
  assert.equal(sentCalls[0].options.isOfflineSync, true);
  assert.equal(sentCalls[0].options.trigger, 'network_recovered');
});

test('MovementQueue: 同一idは冪等に扱い、重複追加しない', async () => {
  const queue = new MovementQueue({
    transport: {
      async send() {
        throw new Error('offline');
      }
    }
  });

  await queue.saveLog(sampleMovement());
  await queue.saveLog(sampleMovement());

  assert.equal(queue.totalCount(), 1);
  assert.equal(queue.unsyncedCount(), 1);
});

test('MovementQueue: 100件の未同期ログを欠落なく再送できる', async () => {
  const queue = new MovementQueue({
    transport: {
      async send(batch) {
        assert.equal(batch.length, 100);
        return { ok: true };
      }
    }
  });

  for (let i = 0; i < 100; i += 1) {
    await queue.enqueue(
      sampleMovement({
        id: `018f8f77-6f7a-7000-8000-${String(i).padStart(12, '0')}`,
        minor: 200 + (i % 10)
      })
    );
  }

  const syncedCount = await queue.syncPending({ trigger: 'periodic' });

  assert.equal(syncedCount, 100);
  assert.equal(queue.unsyncedCount(), 0);
});

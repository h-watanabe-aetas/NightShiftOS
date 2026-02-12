import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class SendCall {
  SendCall(this.batch, this.options);

  final List<MovementLog> batch;
  final SyncOptions options;
}

class RecordingTransport implements MovementTransport {
  final List<SendCall> calls = [];
  bool shouldThrow = false;

  @override
  Future<void> send(List<MovementLog> batch, SyncOptions options) async {
    calls.add(SendCall(batch, options));
    if (shouldThrow) {
      throw Exception('offline');
    }
  }
}

MovementLog sampleMovement({
  String id = '018f8f77-6f7a-7000-8000-000000000001',
  String staffId = 'staff-1',
  int minor = 201,
  String action = 'ENTER',
  DateTime? timestamp,
  int rssi = -68,
}) {
  return MovementLog(
    id: id,
    staffId: staffId,
    minor: minor,
    action: action,
    timestamp: timestamp ?? DateTime.parse('2026-02-11T02:00:00.000Z'),
    rssi: rssi,
  );
}

void main() {
  test('saveLog は送信失敗時でも先保存される（Store-and-Forward）', () async {
    final transport = RecordingTransport()..shouldThrow = true;
    final queue = MovementQueue(transport: transport);

    await queue.saveLog(sampleMovement());

    expect(queue.unsyncedCount(), 1);
    expect(transport.calls.length, 1);
    expect(
      queue.getById('018f8f77-6f7a-7000-8000-000000000001')?.isSynced,
      isFalse,
    );
  });

  test('saveLog は送信成功時に isSynced=true へ更新される', () async {
    final transport = RecordingTransport();
    final queue = MovementQueue(transport: transport);

    await queue.saveLog(sampleMovement());

    expect(queue.unsyncedCount(), 0);
    expect(
      queue.getById('018f8f77-6f7a-7000-8000-000000000001')?.isSynced,
      isTrue,
    );
  });

  test('syncPending は未同期ログを一括送信し is_offline_sync=true を付与する', () async {
    final transport = RecordingTransport();
    final queue = MovementQueue(transport: transport);

    await queue.enqueue(
      sampleMovement(id: '018f8f77-6f7a-7000-8000-000000000010'),
    );
    await queue.enqueue(
      sampleMovement(
        id: '018f8f77-6f7a-7000-8000-000000000011',
        minor: 202,
      ),
    );

    final syncedCount = await queue.syncPending(trigger: SyncTrigger.networkRecovered);

    expect(syncedCount, 2);
    expect(queue.unsyncedCount(), 0);
    expect(transport.calls.length, 1);
    expect(transport.calls.first.options.isOfflineSync, isTrue);
    expect(transport.calls.first.options.trigger, SyncTrigger.networkRecovered);
  });

  test('同一idは冪等に扱い、重複追加しない', () async {
    final transport = RecordingTransport()..shouldThrow = true;
    final queue = MovementQueue(transport: transport);

    await queue.saveLog(sampleMovement());
    await queue.saveLog(sampleMovement());

    expect(queue.totalCount(), 1);
    expect(queue.unsyncedCount(), 1);
  });

  test('100件の未同期ログを欠落なく再送できる', () async {
    final transport = RecordingTransport();
    final queue = MovementQueue(transport: transport);

    for (var i = 0; i < 100; i += 1) {
      await queue.enqueue(
        sampleMovement(
          id: '018f8f77-6f7a-7000-8000-${i.toString().padLeft(12, '0')}',
          minor: 200 + (i % 10),
        ),
      );
    }

    final syncedCount = await queue.syncPending(trigger: SyncTrigger.periodic);

    expect(syncedCount, 100);
    expect(queue.unsyncedCount(), 0);
    expect(transport.calls.length, 1);
    expect(transport.calls.first.batch.length, 100);
  });
}

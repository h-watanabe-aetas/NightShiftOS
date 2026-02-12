import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class SpySyncQueue implements SyncQueue {
  final List<SyncTrigger> triggers = [];

  @override
  Future<int> syncPending({SyncTrigger trigger = SyncTrigger.manual}) async {
    triggers.add(trigger);
    return 3;
  }
}

void main() {
  test('接続回復/起動時/定期実行の各トリガで syncPending を呼ぶ', () async {
    final queue = SpySyncQueue();
    final worker = SyncWorker(queue: queue);

    await worker.onNetworkRecovered();
    await worker.onAppLaunch();
    await worker.onPeriodic();

    expect(
      queue.triggers,
      [
        SyncTrigger.networkRecovered,
        SyncTrigger.appLaunch,
        SyncTrigger.periodic,
      ],
    );
  });
}

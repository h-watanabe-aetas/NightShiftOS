import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class SpySyncQueue implements SyncQueue {
  final List<SyncTrigger> triggers = [];

  @override
  Future<int> syncPending({SyncTrigger trigger = SyncTrigger.manual}) async {
    triggers.add(trigger);
    return 1;
  }
}

void main() {
  test('startでappLaunch再送を実行する', () async {
    final queue = SpySyncQueue();
    final worker = SyncWorker(queue: queue);
    final coordinator = AppRuntimeCoordinator(
      syncWorker: worker,
      connectivityChanges: const Stream.empty(),
      periodicInterval: Duration.zero,
    );
    addTearDown(coordinator.dispose);

    await coordinator.start();

    expect(queue.triggers, [SyncTrigger.appLaunch]);
  });

  test('接続状態が false -> true に遷移した時だけ networkRecovered を実行する', () async {
    final queue = SpySyncQueue();
    final worker = SyncWorker(queue: queue);
    final controller = StreamController<bool>.broadcast();
    final coordinator = AppRuntimeCoordinator(
      syncWorker: worker,
      connectivityChanges: controller.stream,
      periodicInterval: Duration.zero,
    );
    addTearDown(() async {
      coordinator.dispose();
      await controller.close();
    });

    await coordinator.start();
    controller.add(false);
    controller.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      queue.triggers,
      [
        SyncTrigger.appLaunch,
        SyncTrigger.networkRecovered,
      ],
    );
  });

  test('periodic intervalで定期再送を実行する', () async {
    final queue = SpySyncQueue();
    final worker = SyncWorker(queue: queue);
    final coordinator = AppRuntimeCoordinator(
      syncWorker: worker,
      connectivityChanges: const Stream.empty(),
      periodicInterval: const Duration(milliseconds: 20),
    );
    addTearDown(coordinator.dispose);

    await coordinator.start();
    await Future<void>.delayed(const Duration(milliseconds: 70));

    expect(queue.triggers.first, SyncTrigger.appLaunch);
    expect(
      queue.triggers.where((trigger) => trigger == SyncTrigger.periodic).length,
      greaterThanOrEqualTo(2),
    );
  });
}

import 'movement_log.dart';
import 'movement_log_sink.dart';
import 'movement_transport.dart';
import 'sync_options.dart';
import 'sync_queue.dart';
import 'sync_trigger.dart';

class MovementQueue implements SyncQueue, MovementLogSink {
  MovementQueue({required MovementTransport transport})
      : _transport = transport;

  final MovementTransport _transport;
  final Map<String, MovementLog> _logs = {};

  int totalCount() => _logs.length;

  MovementLog? getById(String id) => _logs[id];

  List<MovementLog> listUnsynced() {
    return _logs.values.where((item) => !item.isSynced).toList(growable: false);
  }

  int unsyncedCount() => listUnsynced().length;

  Future<MovementLog> enqueue(MovementLog movement) async {
    final existing = _logs[movement.id];
    if (existing != null) {
      return existing;
    }
    _logs[movement.id] = movement;
    return movement;
  }

  @override
  Future<MovementLog> saveLog(MovementLog movement) async {
    final queued = await enqueue(movement.copyWith(isSynced: false));
    if (queued.isSynced) {
      return queued;
    }

    try {
      await _transport.send(
        [queued],
        const SyncOptions(
          isOfflineSync: false,
          trigger: SyncTrigger.immediate,
        ),
      );
      final synced = queued.copyWith(isSynced: true);
      _logs[queued.id] = synced;
      return synced;
    } catch (_) {
      final unsynced = queued.copyWith(isSynced: false);
      _logs[queued.id] = unsynced;
      return unsynced;
    }
  }

  @override
  Future<int> syncPending({SyncTrigger trigger = SyncTrigger.manual}) async {
    final pending = listUnsynced();
    if (pending.isEmpty) {
      return 0;
    }

    try {
      await _transport.send(
        pending,
        SyncOptions(
          isOfflineSync: true,
          trigger: trigger,
        ),
      );

      for (final item in pending) {
        _logs[item.id] = item.copyWith(isSynced: true);
      }
      return pending.length;
    } catch (_) {
      return 0;
    }
  }
}

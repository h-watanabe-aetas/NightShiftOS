import 'sync_queue.dart';
import 'sync_trigger.dart';

class SyncWorker {
  SyncWorker({required SyncQueue queue}) : _queue = queue;

  final SyncQueue _queue;

  Future<int> onNetworkRecovered() {
    return _queue.syncPending(trigger: SyncTrigger.networkRecovered);
  }

  Future<int> onAppLaunch() {
    return _queue.syncPending(trigger: SyncTrigger.appLaunch);
  }

  Future<int> onPeriodic() {
    return _queue.syncPending(trigger: SyncTrigger.periodic);
  }
}

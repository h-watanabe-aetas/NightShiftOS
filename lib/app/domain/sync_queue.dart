import 'sync_trigger.dart';

abstract class SyncQueue {
  Future<int> syncPending({SyncTrigger trigger = SyncTrigger.manual});
}

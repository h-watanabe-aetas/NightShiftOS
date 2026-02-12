import 'sync_trigger.dart';

class SyncOptions {
  const SyncOptions({
    required this.isOfflineSync,
    required this.trigger,
  });

  final bool isOfflineSync;
  final SyncTrigger trigger;
}

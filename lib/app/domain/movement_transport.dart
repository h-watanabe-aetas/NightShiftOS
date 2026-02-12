import 'movement_log.dart';
import 'sync_options.dart';

abstract class MovementTransport {
  Future<void> send(List<MovementLog> batch, SyncOptions options);
}

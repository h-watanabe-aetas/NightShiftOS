import 'movement_log.dart';

abstract class MovementLogSink {
  Future<MovementLog> saveLog(MovementLog log);
}

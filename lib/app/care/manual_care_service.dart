import '../domain/movement_log.dart';
import '../domain/movement_log_sink.dart';
import '../domain/uuid_v7.dart';
import 'care_action.dart';

typedef CareIdGenerator = String Function();

class ManualCareService {
  ManualCareService({
    required MovementLogSink sink,
    CareIdGenerator? idGenerator,
  })  : _sink = sink,
        _idGenerator = idGenerator ?? createUuidV7;

  final MovementLogSink _sink;
  final CareIdGenerator _idGenerator;

  Future<MovementLog> recordCare({
    required String staffId,
    required int? minor,
    required CareAction action,
    DateTime? timestamp,
  }) {
    final log = MovementLog(
      id: _idGenerator(),
      staffId: staffId,
      minor: minor,
      action: action.wireAction,
      timestamp: timestamp ?? DateTime.now().toUtc(),
      rssi: null,
    );
    return _sink.saveLog(log);
  }
}

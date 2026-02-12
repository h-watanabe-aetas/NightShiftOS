import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class FakeMovementSink implements MovementLogSink {
  final List<MovementLog> saved = [];

  @override
  Future<MovementLog> saveLog(MovementLog log) async {
    saved.add(log);
    return log.copyWith(isSynced: true);
  }
}

void main() {
  test('1タップで CARE_* ログを生成し保存する', () async {
    final sink = FakeMovementSink();
    final service = ManualCareService(
      sink: sink,
      idGenerator: () => 'care-id-1',
    );

    final result = await service.recordCare(
      staffId: 'staff-1',
      minor: 201,
      action: CareAction.toilet,
      timestamp: DateTime.parse('2026-02-11T03:10:00.000Z'),
    );

    expect(sink.saved.length, 1);
    expect(sink.saved.first.action, 'CARE_TOILET');
    expect(result.isSynced, isTrue);
  });
}

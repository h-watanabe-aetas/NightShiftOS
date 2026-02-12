import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  testWidgets('現在地/未送信/6アクションを表示する', (tester) async {
    final sink = FakeMovementSink();
    final service = ManualCareService(
      sink: sink,
      idGenerator: () => 'care-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manualCareServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          home: DashboardScreen(
            staffId: 'staff-1',
            viewModel: DashboardViewModel(
              staffName: 'Sato',
              facilityName: 'Aetas Home',
              currentMinor: 201,
              isMonitoring: true,
              unsyncedCount: 2,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('201号室'), findsOneWidget);
    expect(find.text('未送信 2件'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(6));
  });

  testWidgets('トイレボタン1タップで CARE_TOILET を保存', (tester) async {
    final sink = FakeMovementSink();
    final service = ManualCareService(
      sink: sink,
      idGenerator: () => 'care-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manualCareServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          home: DashboardScreen(
            staffId: 'staff-1',
            viewModel: DashboardViewModel(
              staffName: 'Sato',
              facilityName: 'Aetas Home',
              currentMinor: 201,
              isMonitoring: true,
              unsyncedCount: 0,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('action-toilet')));
    await tester.pumpAndSettle();

    expect(sink.saved.length, 1);
    expect(sink.saved.first.action, 'CARE_TOILET');
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';
import 'dart:async';

class FakePermissionsGateway implements PermissionsGateway {
  @override
  Future<PermissionState> getStatus(AppPermission permission) async {
    return PermissionState.granted;
  }

  @override
  Future<PermissionState> request(AppPermission permission) async {
    return PermissionState.granted;
  }
}

class FakeBeaconRangingSource implements BeaconRangingSource {
  final StreamController<List<BeaconReading>> _controller =
      StreamController.broadcast();
  int? lastFacilityId;

  @override
  Stream<List<BeaconReading>> watchRanging({required int facilityId}) {
    lastFacilityId = facilityId;
    return _controller.stream;
  }

  void emit(List<BeaconReading> readings) {
    _controller.add(readings);
  }

  Future<void> dispose() => _controller.close();
}

class FakeBeaconMonitoringSource implements BeaconMonitoringSource {
  final StreamController<BeaconMonitoringEvent> _controller =
      StreamController.broadcast();
  int? lastFacilityId;

  @override
  Stream<BeaconMonitoringEvent> watchMonitoring({required int facilityId}) {
    lastFacilityId = facilityId;
    return _controller.stream;
  }

  void emit(BeaconMonitoringEvent event) {
    _controller.add(event);
  }

  Future<void> dispose() => _controller.close();
}

class SpyBeaconService extends BeaconService {
  SpyBeaconService() : super(idGenerator: () => 'id-test');

  int startCalls = 0;
  int stopCalls = 0;
  AuthState? lastAuthState;

  @override
  void startMonitoring(AuthState authState) {
    startCalls += 1;
    lastAuthState = authState;
    super.startMonitoring(authState);
  }

  @override
  void stopMonitoring() {
    stopCalls += 1;
    super.stopMonitoring();
  }
}

class FakeMovementSink implements MovementLogSink {
  final List<MovementLog> saved = [];

  @override
  Future<MovementLog> saveLog(MovementLog log) async {
    saved.add(log);
    return log;
  }
}

void main() {
  testWidgets('未認証時は login に遷移する', (tester) async {
    final container = ProviderContainer(
      overrides: [
        permissionsGatewayProvider.overrideWithValue(FakePermissionsGateway()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NightShiftApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-button')), findsOneWidget);
  });

  testWidgets('認証済みかつfacility未解決時は onboarding に遷移する', (tester) async {
    final container = ProviderContainer(
      overrides: [
        permissionsGatewayProvider.overrideWithValue(FakePermissionsGateway()),
      ],
    );
    addTearDown(container.dispose);

    container.read(authStateProvider.notifier).state = const AuthState(
      staffId: 'staff-1',
      facilityId: null,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NightShiftApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('権限セットアップ'), findsOneWidget);
  });

  testWidgets('dashboardで業務開始後にranging結果を購読して現在地minorを更新する', (tester) async {
    final beacon = FakeBeaconRangingSource();
    final monitoring = FakeBeaconMonitoringSource();
    final container = ProviderContainer(
      overrides: [
        permissionsGatewayProvider.overrideWithValue(FakePermissionsGateway()),
        beaconRangingSourceProvider.overrideWithValue(beacon),
        beaconMonitoringSourceProvider.overrideWithValue(monitoring),
      ],
    );
    addTearDown(() async {
      await beacon.dispose();
      await monitoring.dispose();
      container.dispose();
    });

    container.read(authStateProvider.notifier).state = const AuthState(
      staffId: 'staff-1',
      facilityId: 1,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NightShiftApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('移動中...'), findsOneWidget);
    expect(beacon.lastFacilityId, isNull);

    await tester.tap(find.byKey(const Key('monitoring-toggle')));
    await tester.pumpAndSettle();
    expect(container.read(monitoringEnabledProvider), isTrue);
    expect(beacon.lastFacilityId, 1);

    beacon.emit(const [
      BeaconReading(minor: 201, rssi: -81),
      BeaconReading(minor: 202, rssi: -72),
    ]);

    await tester.pump();
    await tester.pump();

    expect(container.read(currentMinorProvider), 202);
    expect(find.text('202号室'), findsOneWidget);
  });

  testWidgets('業務開始トグルONで監視開始し、OFFで監視停止と現在地クリアを行う', (tester) async {
    final beacon = FakeBeaconRangingSource();
    final monitoring = FakeBeaconMonitoringSource();
    final spyBeaconService = SpyBeaconService();
    final container = ProviderContainer(
      overrides: [
        permissionsGatewayProvider.overrideWithValue(FakePermissionsGateway()),
        beaconRangingSourceProvider.overrideWithValue(beacon),
        beaconMonitoringSourceProvider.overrideWithValue(monitoring),
        beaconServiceProvider.overrideWithValue(spyBeaconService),
      ],
    );
    addTearDown(() async {
      await beacon.dispose();
      await monitoring.dispose();
      container.dispose();
    });

    container.read(authStateProvider.notifier).state = const AuthState(
      staffId: 'staff-1',
      facilityId: 1,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NightShiftApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(monitoringEnabledProvider), isFalse);
    expect(find.text('停止中'), findsOneWidget);
    expect(spyBeaconService.startCalls, 0);

    beacon.emit(const [BeaconReading(minor: 201, rssi: -72)]);
    await tester.pump();
    await tester.pump();
    expect(container.read(currentMinorProvider), isNull);

    await tester.tap(find.byKey(const Key('monitoring-toggle')));
    await tester.pumpAndSettle();

    expect(container.read(monitoringEnabledProvider), isTrue);
    expect(spyBeaconService.startCalls, 1);
    expect(spyBeaconService.lastAuthState?.facilityId, 1);
    expect(find.text('監視中'), findsOneWidget);

    beacon.emit(const [BeaconReading(minor: 202, rssi: -70)]);
    await tester.pump();
    await tester.pump();
    expect(container.read(currentMinorProvider), 202);
    expect(find.text('202号室'), findsOneWidget);

    await tester.tap(find.byKey(const Key('monitoring-toggle')));
    await tester.pumpAndSettle();

    expect(container.read(monitoringEnabledProvider), isFalse);
    expect(spyBeaconService.stopCalls, 1);
    expect(container.read(currentMinorProvider), isNull);
    expect(find.text('移動中...'), findsOneWidget);

    beacon.emit(const [BeaconReading(minor: 203, rssi: -69)]);
    await tester.pump();
    await tester.pump();
    expect(container.read(currentMinorProvider), isNull);
  });

  testWidgets('monitoring enter/exitイベントで自動MovementLogを保存する', (tester) async {
    final beacon = FakeBeaconRangingSource();
    final monitoring = FakeBeaconMonitoringSource();
    final movementSink = FakeMovementSink();
    final container = ProviderContainer(
      overrides: [
        permissionsGatewayProvider.overrideWithValue(FakePermissionsGateway()),
        beaconRangingSourceProvider.overrideWithValue(beacon),
        beaconMonitoringSourceProvider.overrideWithValue(monitoring),
        movementLogSinkProvider.overrideWithValue(movementSink),
      ],
    );
    addTearDown(() async {
      await beacon.dispose();
      await monitoring.dispose();
      container.dispose();
    });

    container.read(authStateProvider.notifier).state = const AuthState(
      staffId: 'staff-1',
      facilityId: 1,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NightShiftApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('monitoring-toggle')));
    await tester.pumpAndSettle();

    beacon.emit(const [BeaconReading(minor: 202, rssi: -72)]);
    await tester.pump();
    await tester.pump();

    monitoring.emit(
      const BeaconMonitoringEvent(
        type: BeaconMonitoringEventType.enter,
        facilityId: 1,
      ),
    );
    monitoring.emit(
      const BeaconMonitoringEvent(
        type: BeaconMonitoringEventType.exit,
        facilityId: 1,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(movementSink.saved.length, 2);
    expect(movementSink.saved[0].action, 'ENTER');
    expect(movementSink.saved[0].staffId, 'staff-1');
    expect(movementSink.saved[0].minor, 202);
    expect(movementSink.saved[1].action, 'EXIT');
    expect(movementSink.saved[1].staffId, 'staff-1');
    expect(movementSink.saved[1].minor, 202);
  });
}

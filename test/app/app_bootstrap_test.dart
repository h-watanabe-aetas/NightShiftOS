import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class FakeFirebaseInitializer implements FirebaseInitializer {
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }
}

class FakeFcmSource implements FcmSource {
  final StreamController<Map<String, String>> _foreground = StreamController.broadcast();
  final StreamController<Map<String, String>> _opened = StreamController.broadcast();

  Map<String, String>? initial;

  @override
  Stream<Map<String, String>> get onForeground => _foreground.stream;

  @override
  Stream<Map<String, String>> get onOpenedApp => _opened.stream;

  @override
  Future<Map<String, String>?> getInitialMessage() async => initial;

  void emitForeground(Map<String, String> data) => _foreground.add(data);

  void emitOpened(Map<String, String> data) => _opened.add(data);
}

class SpyDispatcher extends FcmCriticalAlertDispatcher {
  SpyDispatcher()
      : super(
          handler: CriticalAlertHandler(
            notifier: _NoopNotifier(),
            navigation: _NoopNav(),
          ),
        );

  final List<AlertAppState> states = [];

  @override
  Future<CriticalAlertResult?> dispatch({
    required Map<String, String> data,
    required AlertAppState appState,
  }) async {
    states.add(appState);
    return const CriticalAlertResult(
      latency: Duration(milliseconds: 100),
      meetsP95Target: true,
    );
  }
}

class _NoopNotifier implements CriticalAlertNotifier {
  @override
  Future<void> playAlarm() async {}

  @override
  Future<DateTime> showCritical(CriticalAlert alert, {required bool useSystemNotification}) async {
    return DateTime.now();
  }

  @override
  Future<void> vibrate() async {}
}

class _NoopNav implements AlertNavigation {
  @override
  Future<void> openRoom(CriticalAlert alert) async {}
}

void main() {
  test('initializeでfirebase初期化し、foreground/background/initialを購読する', () async {
    final firebase = FakeFirebaseInitializer();
    final source = FakeFcmSource()
      ..initial = {
        'room_label': '201号室',
        'minor': '201',
        'received_at': '2026-02-11T05:00:00.000Z',
      };
    final dispatcher = SpyDispatcher();

    final bootstrap = AppBootstrap(
      firebase: firebase,
      source: source,
      dispatcher: dispatcher,
    );

    await bootstrap.initialize();

    source.emitForeground({
      'room_label': '202号室',
      'minor': '202',
      'received_at': '2026-02-11T05:00:01.000Z',
    });
    source.emitOpened({
      'room_label': '203号室',
      'minor': '203',
      'received_at': '2026-02-11T05:00:02.000Z',
    });

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(firebase.initialized, isTrue);
    expect(dispatcher.states, [
      AlertAppState.terminated,
      AlertAppState.foreground,
      AlertAppState.background,
    ]);
  });
}

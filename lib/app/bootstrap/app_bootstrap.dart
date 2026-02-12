import '../notifications/critical_alert_handler.dart';
import '../notifications/fcm_critical_alert_dispatcher.dart';

abstract class FirebaseInitializer {
  Future<void> initialize();
}

abstract class FcmSource {
  Stream<Map<String, String>> get onForeground;

  Stream<Map<String, String>> get onOpenedApp;

  Future<Map<String, String>?> getInitialMessage();
}

class AppBootstrap {
  AppBootstrap({
    required FirebaseInitializer firebase,
    required FcmSource source,
    required FcmCriticalAlertDispatcher dispatcher,
  })  : _firebase = firebase,
        _source = source,
        _dispatcher = dispatcher;

  final FirebaseInitializer _firebase;
  final FcmSource _source;
  final FcmCriticalAlertDispatcher _dispatcher;

  Future<void> initialize() async {
    await _firebase.initialize();

    final initial = await _source.getInitialMessage();
    if (initial != null) {
      await _dispatcher.dispatch(
        data: initial,
        appState: AlertAppState.terminated,
      );
    }

    _source.onForeground.listen((data) {
      _dispatcher.dispatch(
        data: data,
        appState: AlertAppState.foreground,
      );
    });

    _source.onOpenedApp.listen((data) {
      _dispatcher.dispatch(
        data: data,
        appState: AlertAppState.background,
      );
    });
  }
}

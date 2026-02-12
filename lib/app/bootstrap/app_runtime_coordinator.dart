import 'dart:async';

import '../domain/sync_worker.dart';

class AppRuntimeCoordinator {
  AppRuntimeCoordinator({
    required SyncWorker syncWorker,
    required Stream<bool> connectivityChanges,
    this.periodicInterval = const Duration(minutes: 15),
  })  : _syncWorker = syncWorker,
        _connectivityChanges = connectivityChanges;

  final SyncWorker _syncWorker;
  final Stream<bool> _connectivityChanges;
  final Duration periodicInterval;

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _periodicTimer;
  bool _started = false;
  bool? _isConnected;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    await _syncWorker.onAppLaunch();

    _connectivitySubscription = _connectivityChanges.listen((isConnected) {
      final wasConnected = _isConnected;
      _isConnected = isConnected;
      if (wasConnected == false && isConnected) {
        unawaited(_syncWorker.onNetworkRecovered());
      }
    });

    if (periodicInterval > Duration.zero) {
      _periodicTimer = Timer.periodic(periodicInterval, (_) {
        unawaited(_syncWorker.onPeriodic());
      });
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _started = false;
    _isConnected = null;
  }
}

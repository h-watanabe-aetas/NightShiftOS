enum SyncTrigger {
  immediate,
  networkRecovered,
  appLaunch,
  periodic,
  manual,
}

extension SyncTriggerWire on SyncTrigger {
  String get wireValue {
    switch (this) {
      case SyncTrigger.immediate:
        return 'immediate';
      case SyncTrigger.networkRecovered:
        return 'network_recovered';
      case SyncTrigger.appLaunch:
        return 'app_launch';
      case SyncTrigger.periodic:
        return 'periodic';
      case SyncTrigger.manual:
        return 'manual';
    }
  }
}

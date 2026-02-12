class NativeSettingsValidator {
  static const Set<String> requiredIosKeys = {
    'NSLocationAlwaysAndWhenInUseUsageDescription',
    'NSLocationWhenInUseUsageDescription',
    'UIBackgroundModes:location',
    'UIBackgroundModes:fetch',
    'UIBackgroundModes:remote-notification',
  };

  static const Set<String> requiredAndroidPermissions = {
    'BLUETOOTH_SCAN',
    'ACCESS_BACKGROUND_LOCATION',
    'FOREGROUND_SERVICE_LOCATION',
  };

  bool validateIosKeys(Set<String> configuredKeys) {
    return requiredIosKeys.difference(configuredKeys).isEmpty;
  }

  bool validateAndroidPermissions(Set<String> configuredPermissions) {
    return requiredAndroidPermissions.difference(configuredPermissions).isEmpty;
  }
}

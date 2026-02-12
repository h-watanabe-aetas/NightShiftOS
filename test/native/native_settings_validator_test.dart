import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

void main() {
  test('iOS必須キーが揃っていればvalid', () {
    final validator = NativeSettingsValidator();
    final isValid = validator.validateIosKeys(const {
      'NSLocationAlwaysAndWhenInUseUsageDescription',
      'NSLocationWhenInUseUsageDescription',
      'UIBackgroundModes:location',
      'UIBackgroundModes:fetch',
      'UIBackgroundModes:remote-notification',
    });

    expect(isValid, isTrue);
  });

  test('Android必須権限が不足しているとinvalid', () {
    final validator = NativeSettingsValidator();
    final isValid = validator.validateAndroidPermissions(const {
      'BLUETOOTH_SCAN',
      'ACCESS_BACKGROUND_LOCATION',
    });

    expect(isValid, isFalse);
  });
}

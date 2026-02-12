import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Info.plist has required background and location settings', () {
    final file = File('ios/Runner/Info.plist');
    expect(file.existsSync(), isTrue);

    final content = file.readAsStringSync();
    expect(content, contains('NSLocationAlwaysAndWhenInUseUsageDescription'));
    expect(content, contains('NSLocationWhenInUseUsageDescription'));
    expect(content, contains('<string>location</string>'));
    expect(content, contains('<string>fetch</string>'));
    expect(content, contains('<string>remote-notification</string>'));
    expect(content, contains('BGTaskSchedulerPermittedIdentifiers'));
  });

  test('AndroidManifest.xml has required location/bluetooth/foreground permissions', () {
    final file = File('android/app/src/main/AndroidManifest.xml');
    expect(file.existsSync(), isTrue);

    final content = file.readAsStringSync();
    expect(content, contains('android.permission.BLUETOOTH_SCAN'));
    expect(content, contains('android.permission.ACCESS_BACKGROUND_LOCATION'));
    expect(content, contains('android.permission.FOREGROUND_SERVICE_LOCATION'));
  });
}

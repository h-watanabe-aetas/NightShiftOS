import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('android settings.gradle.kts has google-services plugin declaration', () {
    final file = File('android/settings.gradle.kts');
    final content = file.readAsStringSync();

    expect(content, contains('com.google.gms.google-services'));
  });

  test('android app build.gradle.kts applies google-services plugin', () {
    final file = File('android/app/build.gradle.kts');
    final content = file.readAsStringSync();

    expect(content, contains('id("com.google.gms.google-services")'));
  });

  test('firebase config template files exist for iOS/Android', () {
    expect(File('android/app/google-services.json.example').existsSync(), isTrue);
    expect(File('ios/Runner/GoogleService-Info.plist.example').existsSync(), isTrue);
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('firebase initializer references supabase init', () {
    final file = File('lib/main.dart');
    final content = file.readAsStringSync();

    expect(content, contains('initializeSupabaseIfConfigured'));
  });
}

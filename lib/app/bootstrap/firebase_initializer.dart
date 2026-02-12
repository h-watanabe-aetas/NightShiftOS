import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';

import 'app_bootstrap.dart';

class FlutterFirebaseInitializer implements FirebaseInitializer {
  const FlutterFirebaseInitializer();

  @override
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (error, stackTrace) {
      developer.log(
        'Firebase initialize skipped: $error',
        name: 'NightShiftOS.Firebase',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

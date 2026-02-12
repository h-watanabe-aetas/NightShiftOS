import 'package:firebase_messaging/firebase_messaging.dart';

import 'app_bootstrap.dart';

class FirebaseMessagingSource implements FcmSource {
  const FirebaseMessagingSource();

  @override
  Stream<Map<String, String>> get onForeground {
    return FirebaseMessaging.onMessage.map(_normalize);
  }

  @override
  Stream<Map<String, String>> get onOpenedApp {
    return FirebaseMessaging.onMessageOpenedApp.map(_normalize);
  }

  @override
  Future<Map<String, String>?> getInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) {
      return null;
    }
    return _normalize(message);
  }

  Map<String, String> _normalize(RemoteMessage message) {
    return Map<String, String>.from(message.data.map((key, value) => MapEntry(key, '$value')));
  }
}

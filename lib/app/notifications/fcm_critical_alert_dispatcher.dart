import 'package:firebase_messaging/firebase_messaging.dart';

import 'critical_alert.dart';
import 'critical_alert_handler.dart';

class FcmCriticalAlertDispatcher {
  FcmCriticalAlertDispatcher({required CriticalAlertHandler handler}) : _handler = handler;

  final CriticalAlertHandler _handler;

  Future<CriticalAlertResult?> dispatch({
    required Map<String, String> data,
    required AlertAppState appState,
  }) async {
    final roomLabel = data['room_label'];
    final minorRaw = data['minor'];
    if (roomLabel == null || roomLabel.isEmpty || minorRaw == null || minorRaw.isEmpty) {
      return null;
    }

    final minor = int.tryParse(minorRaw);
    if (minor == null) {
      return null;
    }

    final receivedAt = data['received_at'] ?? DateTime.now().toUtc().toIso8601String();
    final alert = CriticalAlert(
      roomLabel: roomLabel,
      minor: minor,
      receivedAt: receivedAt,
    );
    return _handler.handle(alert, appState: appState);
  }

  Future<CriticalAlertResult?> dispatchRemoteMessage(
    RemoteMessage message, {
    required AlertAppState appState,
  }) {
    final normalized = Map<String, String>.from(message.data.map((key, value) => MapEntry(key, '$value')));
    return dispatch(
      data: normalized,
      appState: appState,
    );
  }
}

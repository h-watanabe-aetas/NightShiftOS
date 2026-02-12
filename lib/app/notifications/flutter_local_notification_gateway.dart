import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'local_notification_gateway.dart';

class FlutterLocalNotificationGateway implements LocalNotificationGateway {
  FlutterLocalNotificationGateway({required FlutterLocalNotificationsPlugin plugin}) : _plugin = plugin;

  static const String criticalChannelId = 'critical_alert';
  static const String criticalChannelName = 'Critical Alerts';

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        criticalChannelId,
        criticalChannelName,
        description: 'NightShiftOS critical incident alerts',
        importance: Importance.max,
        playSound: true,
      ),
    );
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required bool useSystemNotification,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        criticalChannelId,
        criticalChannelName,
        channelDescription: 'NightShiftOS critical incident alerts',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: useSystemNotification ? 'system' : 'overlay',
    );
  }
}

abstract class LocalNotificationGateway {
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required bool useSystemNotification,
  });
}

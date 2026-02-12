class CriticalAlert {
  const CriticalAlert({
    required this.roomLabel,
    required this.minor,
    required this.receivedAt,
  });

  final String roomLabel;
  final int? minor;
  final String receivedAt;
}

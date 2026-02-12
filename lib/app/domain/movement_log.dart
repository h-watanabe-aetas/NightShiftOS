class MovementLog {
  const MovementLog({
    required this.id,
    required this.staffId,
    required this.minor,
    required this.action,
    required this.timestamp,
    required this.rssi,
    this.isSynced = false,
  });

  final String id;
  final String staffId;
  final int? minor;
  final String action;
  final DateTime timestamp;
  final int? rssi;
  final bool isSynced;

  MovementLog copyWith({bool? isSynced}) {
    return MovementLog(
      id: id,
      staffId: staffId,
      minor: minor,
      action: action,
      timestamp: timestamp,
      rssi: rssi,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

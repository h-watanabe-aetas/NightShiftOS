class AuthState {
  const AuthState({
    this.staffId,
    this.facilityId,
  });

  final String? staffId;
  final int? facilityId;

  AuthState copyWith({
    String? staffId,
    int? facilityId,
  }) {
    return AuthState(
      staffId: staffId ?? this.staffId,
      facilityId: facilityId ?? this.facilityId,
    );
  }

  bool canStartMonitoring() {
    return staffId != null && staffId!.isNotEmpty && facilityId != null;
  }
}

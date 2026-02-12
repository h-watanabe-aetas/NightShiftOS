class AuthLoginResult {
  const AuthLoginResult({
    required this.userId,
    required this.accessToken,
  });

  final String userId;
  final String accessToken;
}

abstract class AuthGateway {
  Future<AuthLoginResult> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthLoginResult?> currentSession();
}

abstract class ProfileGateway {
  Future<int?> fetchFacilityId({required String userId});
}

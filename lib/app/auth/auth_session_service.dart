import '../domain/auth_state.dart';
import '../network/secure_storage_auth_token_provider.dart';

class AuthSessionService {
  AuthSessionService({
    required SecureStorageGateway storage,
    this.tokenKey = 'access_token',
  }) : _storage = storage;

  final SecureStorageGateway _storage;
  final String tokenKey;

  Future<AuthState> establishSession({
    required String staffId,
    required int? facilityId,
    required String accessToken,
  }) async {
    await _storage.write(tokenKey, accessToken);
    return AuthState(
      staffId: staffId,
      facilityId: facilityId,
    );
  }

  Future<void> clearSession() {
    return _storage.delete(tokenKey);
  }
}

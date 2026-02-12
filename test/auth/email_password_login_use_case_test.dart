import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class FakeAuthGateway implements AuthGateway {
  AuthLoginResult? result;

  @override
  Future<AuthLoginResult?> currentSession() async {
    return result;
  }

  @override
  Future<AuthLoginResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return result ??
        const AuthLoginResult(
          userId: 'user-1',
          accessToken: 'jwt-1',
        );
  }
}

class FakeProfileGateway implements ProfileGateway {
  int? facilityId;

  @override
  Future<int?> fetchFacilityId({required String userId}) async {
    return facilityId;
  }
}

class FakeSecureStorageGateway implements SecureStorageGateway {
  final Map<String, String?> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String? value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

void main() {
  test('email/password ログインで token保存とAuthState確立を行う', () async {
    final authGateway = FakeAuthGateway()
      ..result = const AuthLoginResult(
        userId: 'staff-auth-1',
        accessToken: 'jwt-abc',
      );
    final profileGateway = FakeProfileGateway()..facilityId = 7;
    final storage = FakeSecureStorageGateway();
    final sessionService = AuthSessionService(storage: storage);

    final useCase = EmailPasswordLoginUseCase(
      authGateway: authGateway,
      profileGateway: profileGateway,
      sessionService: sessionService,
    );

    final state = await useCase.execute(
      email: 'test@example.com',
      password: 'password',
    );

    expect(storage.data['access_token'], 'jwt-abc');
    expect(state.staffId, 'staff-auth-1');
    expect(state.facilityId, 7);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class FakeAuthGateway implements AuthGateway {
  AuthLoginResult? session;

  @override
  Future<AuthLoginResult?> currentSession() async {
    return session;
  }

  @override
  Future<AuthLoginResult> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
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
  test('既存セッションがあればAuthState復元とtoken再保存を行う', () async {
    final authGateway = FakeAuthGateway()
      ..session = const AuthLoginResult(
        userId: 'staff-restore-1',
        accessToken: 'jwt-restore',
      );
    final profileGateway = FakeProfileGateway()..facilityId = 3;
    final storage = FakeSecureStorageGateway();
    final sessionService = AuthSessionService(storage: storage);
    final useCase = RestoreSessionUseCase(
      authGateway: authGateway,
      profileGateway: profileGateway,
      sessionService: sessionService,
    );

    final state = await useCase.execute();

    expect(storage.data['access_token'], 'jwt-restore');
    expect(state.staffId, 'staff-restore-1');
    expect(state.facilityId, 3);
  });

  test('既存セッションが無ければ未認証状態を返す', () async {
    final authGateway = FakeAuthGateway()..session = null;
    final profileGateway = FakeProfileGateway()..facilityId = 3;
    final storage = FakeSecureStorageGateway();
    final sessionService = AuthSessionService(storage: storage);
    final useCase = RestoreSessionUseCase(
      authGateway: authGateway,
      profileGateway: profileGateway,
      sessionService: sessionService,
    );

    final state = await useCase.execute();

    expect(storage.data.containsKey('access_token'), isFalse);
    expect(state.staffId, isNull);
    expect(state.facilityId, isNull);
  });
}

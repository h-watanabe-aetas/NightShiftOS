import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

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
  test('establishSession は access_token を保存しAuthStateを返す', () async {
    final storage = FakeSecureStorageGateway();
    final service = AuthSessionService(storage: storage);

    final state = await service.establishSession(
      staffId: 'staff-1',
      facilityId: null,
      accessToken: 'jwt-123',
    );

    expect(storage.data['access_token'], 'jwt-123');
    expect(state.staffId, 'staff-1');
    expect(state.facilityId, isNull);
  });

  test('clearSession は access_token を削除する', () async {
    final storage = FakeSecureStorageGateway()..data['access_token'] = 'jwt-123';
    final service = AuthSessionService(storage: storage);

    await service.clearSession();

    expect(storage.data.containsKey('access_token'), isFalse);
  });
}

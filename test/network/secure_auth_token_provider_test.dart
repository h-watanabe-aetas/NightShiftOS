import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class FakeSecureStorageGateway implements SecureStorageGateway {
  FakeSecureStorageGateway(this.data);

  final Map<String, String?> data;

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
  test('access_token キーからJWTを読み取る', () async {
    final provider = SecureStorageAuthTokenProvider(
      storage: FakeSecureStorageGateway({'access_token': 'jwt-123'}),
    );

    final token = await provider.readAccessToken();

    expect(token, 'jwt-123');
  });

  test('キーが無い場合は null を返す', () async {
    final provider = SecureStorageAuthTokenProvider(
      storage: FakeSecureStorageGateway({}),
    );

    final token = await provider.readAccessToken();

    expect(token, isNull);
  });
}

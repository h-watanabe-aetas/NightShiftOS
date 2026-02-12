import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_token_provider.dart';

abstract class SecureStorageGateway {
  Future<String?> read(String key);

  Future<void> write(String key, String? value);

  Future<void> delete(String key);
}

class FlutterSecureStorageGateway implements SecureStorageGateway {
  FlutterSecureStorageGateway({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write(String key, String? value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }
}

class SecureStorageAuthTokenProvider implements AuthTokenProvider {
  SecureStorageAuthTokenProvider({
    required SecureStorageGateway storage,
    this.key = 'access_token',
  }) : _storage = storage;

  final SecureStorageGateway _storage;
  final String key;

  @override
  Future<String?> readAccessToken() async {
    return _storage.read(key);
  }
}

abstract class AuthTokenProvider {
  Future<String?> readAccessToken();
}

class EmptyAuthTokenProvider implements AuthTokenProvider {
  const EmptyAuthTokenProvider();

  @override
  Future<String?> readAccessToken() async {
    return null;
  }
}

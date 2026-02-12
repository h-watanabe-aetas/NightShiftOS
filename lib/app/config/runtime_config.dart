class RuntimeConfig {
  const RuntimeConfig({
    required this.apiBaseUrl,
    this.supabaseAnonKey = '',
  });

  static const String _fallbackBaseUrl = 'https://example.supabase.co';

  final String apiBaseUrl;
  final String supabaseAnonKey;

  String get normalizedApiBaseUrl {
    final trimmed = apiBaseUrl.trim();
    if (trimmed.isEmpty) {
      return _fallbackBaseUrl;
    }
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Uri get movementIngestEndpoint {
    return Uri.parse('$normalizedApiBaseUrl/functions/v1/ingest-movement');
  }
}

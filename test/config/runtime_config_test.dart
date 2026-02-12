import 'package:flutter_test/flutter_test.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

void main() {
  test('baseUrl末尾のスラッシュを正規化する', () {
    const config = RuntimeConfig(apiBaseUrl: 'https://abc.supabase.co/');
    expect(config.normalizedApiBaseUrl, 'https://abc.supabase.co');
    expect(
      config.movementIngestEndpoint.toString(),
      'https://abc.supabase.co/functions/v1/ingest-movement',
    );
  });

  test('empty値の場合はデフォルトを使う', () {
    const config = RuntimeConfig(apiBaseUrl: '');
    expect(config.normalizedApiBaseUrl, 'https://example.supabase.co');
  });

  test('supabase anon keyを保持する', () {
    const config = RuntimeConfig(
      apiBaseUrl: 'https://abc.supabase.co',
      supabaseAnonKey: 'anon-key',
    );
    expect(config.supabaseAnonKey, 'anon-key');
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nightshiftos_app/nightshiftos_app.dart';

class FakeTokenProvider implements AuthTokenProvider {
  FakeTokenProvider(this.token);

  final String? token;

  @override
  Future<String?> readAccessToken() async => token;
}

MovementLog movement(String id, {int minor = 201, String action = 'ENTER'}) {
  return MovementLog(
    id: id,
    staffId: 'staff-1',
    minor: minor,
    action: action,
    timestamp: DateTime.parse('2026-02-11T04:00:00.000Z'),
    rssi: -68,
  );
}

void main() {
  test('未同期バッチを ingest-movement へ JWT付きでPOSTする', () async {
    late Map<String, dynamic> body;
    late http.Request captured;

    final client = MockClient((request) async {
      captured = request;
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{}', 200);
    });

    final transport = HttpMovementTransport(
      endpoint: Uri.parse('https://example.supabase.co/functions/v1/ingest-movement'),
      tokenProvider: FakeTokenProvider('jwt-token'),
      client: client,
    );

    await transport.send(
      [
        movement('id-1', minor: 201, action: 'ENTER'),
        movement('id-2', minor: 202, action: 'EXIT'),
      ],
      const SyncOptions(
        isOfflineSync: true,
        trigger: SyncTrigger.networkRecovered,
      ),
    );

    expect(captured.method, 'POST');
    expect(captured.headers['authorization'], 'Bearer jwt-token');
    expect(body['is_offline_sync'], true);
    expect(body['sync_trigger'], 'network_recovered');
    expect((body['movements'] as List).length, 2);
  });

  test('トークン未取得時は送信を失敗させる', () async {
    final transport = HttpMovementTransport(
      endpoint: Uri.parse('https://example.supabase.co/functions/v1/ingest-movement'),
      tokenProvider: FakeTokenProvider(null),
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    expect(
      () => transport.send(
        [movement('id-1')],
        const SyncOptions(
          isOfflineSync: false,
          trigger: SyncTrigger.immediate,
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('APIが非2xx応答の場合は例外を投げる', () async {
    final transport = HttpMovementTransport(
      endpoint: Uri.parse('https://example.supabase.co/functions/v1/ingest-movement'),
      tokenProvider: FakeTokenProvider('jwt-token'),
      client: MockClient((_) async => http.Response('{"error":"bad"}', 500)),
    );

    expect(
      () => transport.send(
        [movement('id-1')],
        const SyncOptions(
          isOfflineSync: false,
          trigger: SyncTrigger.immediate,
        ),
      ),
      throwsA(isA<HttpMovementTransportException>()),
    );
  });
}

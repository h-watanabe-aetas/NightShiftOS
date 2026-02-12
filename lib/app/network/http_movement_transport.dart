import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/movement_log.dart';
import '../domain/movement_transport.dart';
import '../domain/sync_options.dart';
import '../domain/sync_trigger.dart';
import 'auth_token_provider.dart';

class HttpMovementTransportException implements Exception {
  HttpMovementTransportException({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'HttpMovementTransportException(statusCode: $statusCode, body: $body)';
  }
}

class HttpMovementTransport implements MovementTransport {
  HttpMovementTransport({
    required Uri endpoint,
    required AuthTokenProvider tokenProvider,
    required http.Client client,
  })  : _endpoint = endpoint,
        _tokenProvider = tokenProvider,
        _client = client;

  final Uri _endpoint;
  final AuthTokenProvider _tokenProvider;
  final http.Client _client;

  @override
  Future<void> send(List<MovementLog> batch, SyncOptions options) async {
    if (batch.isEmpty) {
      return;
    }

    final token = await _tokenProvider.readAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('JWT token is required for ingest-movement');
    }

    final body = jsonEncode({
      'movements': batch.map((item) {
        return {
          'id': item.id,
          'staff_id': item.staffId,
          'minor': item.minor,
          'action': item.action,
          'timestamp': item.timestamp.toUtc().toIso8601String(),
          'rssi': item.rssi,
        };
      }).toList(growable: false),
      'is_offline_sync': options.isOfflineSync,
      'sync_trigger': options.trigger.wireValue,
    });

    final response = await _client.post(
      _endpoint,
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpMovementTransportException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}

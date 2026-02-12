import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gateways.dart';

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Future<AuthLoginResult?> currentSession() async {
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser;
    if (session == null || user == null) {
      return null;
    }
    return AuthLoginResult(
      userId: user.id,
      accessToken: session.accessToken,
    );
  }

  @override
  Future<AuthLoginResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final session = response.session;
    final user = response.user;
    if (session == null || user == null) {
      throw StateError('Supabase sign-in succeeded without session/user');
    }

    return AuthLoginResult(
      userId: user.id,
      accessToken: session.accessToken,
    );
  }
}

class SupabaseProfileGateway implements ProfileGateway {
  SupabaseProfileGateway({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Future<int?> fetchFacilityId({required String userId}) async {
    final response = await _client
        .from('profiles')
        .select('facility_id')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final raw = response['facility_id'];
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }
}

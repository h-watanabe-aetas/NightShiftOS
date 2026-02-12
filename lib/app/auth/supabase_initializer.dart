import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/runtime_config.dart';

Future<void> initializeSupabaseIfConfigured(RuntimeConfig config) async {
  final anonKey = config.supabaseAnonKey.trim();
  if (anonKey.isEmpty) {
    developer.log(
      'SUPABASE_ANON_KEY is empty. Supabase init skipped.',
      name: 'NightShiftOS.Supabase',
    );
    return;
  }

  try {
    final _ = Supabase.instance.client;
    return;
  } catch (_) {
    // Continue and initialize.
  }

  await Supabase.initialize(
    url: config.normalizedApiBaseUrl,
    anonKey: anonKey,
  );
}

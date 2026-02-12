import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/auth/supabase_initializer.dart';
import 'app/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  final runtimeConfig = container.read(runtimeConfigProvider);
  await initializeSupabaseIfConfigured(runtimeConfig);
  if (runtimeConfig.supabaseAnonKey.trim().isNotEmpty) {
    final restored =
        await container.read(restoreSessionUseCaseProvider).execute();
    container.read(authStateProvider.notifier).state = restored;
  }
  await container.read(appBootstrapProvider).initialize();
  await container.read(appRuntimeCoordinatorProvider).start();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NightShiftApp(),
    ),
  );
}

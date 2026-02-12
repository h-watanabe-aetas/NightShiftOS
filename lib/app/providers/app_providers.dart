import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../bootstrap/app_bootstrap.dart';
import '../bootstrap/app_runtime_coordinator.dart';
import '../beacon/beacon_monitoring_source.dart';
import '../beacon/beacon_ranging_source.dart';
import '../beacon/flutter_beacon_monitoring_source.dart';
import '../beacon/flutter_beacon_ranging_source.dart';
import '../bootstrap/firebase_initializer.dart';
import '../bootstrap/firebase_messaging_source.dart';
import '../config/runtime_config.dart';
import '../auth/auth_session_service.dart';
import '../auth/auth_gateways.dart';
import '../auth/email_password_login_use_case.dart';
import '../auth/restore_session_use_case.dart';
import '../auth/supabase_auth_gateways.dart';
import '../care/manual_care_service.dart';
import '../dashboard/dashboard_view_model.dart';
import '../domain/auth_state.dart';
import '../domain/beacon_service.dart';
import '../domain/movement_log_sink.dart';
import '../domain/movement_queue.dart';
import '../domain/movement_transport.dart';
import '../network/auth_token_provider.dart';
import '../network/connectivity_plus_status_source.dart';
import '../network/connectivity_status_source.dart';
import '../network/http_movement_transport.dart';
import '../network/secure_storage_auth_token_provider.dart';
import '../native/native_settings_validator.dart';
import '../notifications/alert_feedback.dart';
import '../notifications/alert_navigation.dart';
import '../notifications/critical_alert_handler.dart';
import '../notifications/critical_alert_notifier.dart';
import '../notifications/fcm_critical_alert_dispatcher.dart';
import '../notifications/flutter_critical_alert_notifier.dart';
import '../notifications/flutter_local_notification_gateway.dart';
import '../notifications/local_notification_gateway.dart';
import '../notifications/provider_alert_navigation.dart';
import '../notifications/system_alert_feedback.dart';
import '../onboarding/permission_handler_gateway.dart';
import '../onboarding/onboarding_wizard.dart';
import '../onboarding/permissions_gateway.dart';
import '../domain/sync_worker.dart';

final authStateProvider = StateProvider<AuthState>((_) => const AuthState());

final runtimeConfigProvider = Provider<RuntimeConfig>((_) {
  return const RuntimeConfig(
    apiBaseUrl: String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://example.supabase.co'),
    supabaseAnonKey:
        String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );
});

final apiBaseUrlProvider = Provider<String>((ref) {
  final config = ref.watch(runtimeConfigProvider);
  return config.normalizedApiBaseUrl;
});

final movementIngestEndpointProvider = Provider<Uri>((ref) {
  final config = ref.watch(runtimeConfigProvider);
  return config.movementIngestEndpoint;
});

final secureStorageGatewayProvider = Provider<SecureStorageGateway>((_) {
  return FlutterSecureStorageGateway();
});

final authSessionServiceProvider = Provider<AuthSessionService>((ref) {
  final storage = ref.watch(secureStorageGatewayProvider);
  return AuthSessionService(storage: storage);
});

final authTokenProvider = Provider<AuthTokenProvider>((ref) {
  final storage = ref.watch(secureStorageGatewayProvider);
  return SecureStorageAuthTokenProvider(storage: storage);
});

final supabaseClientProvider = Provider<SupabaseClient>((_) {
  return Supabase.instance.client;
});

final authGatewayProvider = Provider<AuthGateway>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthGateway(client: client);
});

final profileGatewayProvider = Provider<ProfileGateway>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseProfileGateway(client: client);
});

final emailPasswordLoginUseCaseProvider =
    Provider<EmailPasswordLoginUseCase>((ref) {
  final authGateway = ref.watch(authGatewayProvider);
  final profileGateway = ref.watch(profileGatewayProvider);
  final sessionService = ref.watch(authSessionServiceProvider);
  return EmailPasswordLoginUseCase(
    authGateway: authGateway,
    profileGateway: profileGateway,
    sessionService: sessionService,
  );
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  final authGateway = ref.watch(authGatewayProvider);
  final profileGateway = ref.watch(profileGatewayProvider);
  final sessionService = ref.watch(authSessionServiceProvider);
  return RestoreSessionUseCase(
    authGateway: authGateway,
    profileGateway: profileGateway,
    sessionService: sessionService,
  );
});

final httpClientProvider = Provider<http.Client>((_) {
  return http.Client();
});

final movementTransportProvider = Provider<MovementTransport>((ref) {
  final endpoint = ref.watch(movementIngestEndpointProvider);
  final tokenProvider = ref.watch(authTokenProvider);
  final client = ref.watch(httpClientProvider);
  return HttpMovementTransport(
    endpoint: endpoint,
    tokenProvider: tokenProvider,
    client: client,
  );
});

final beaconServiceProvider = Provider<BeaconService>((_) => BeaconService());

final movementQueueProvider = Provider<MovementQueue>((ref) {
  final transport = ref.watch(movementTransportProvider);
  return MovementQueue(transport: transport);
});

final movementLogSinkProvider = Provider<MovementLogSink>((ref) {
  return ref.watch(movementQueueProvider);
});

final beaconRangingSourceProvider = Provider<BeaconRangingSource>((_) {
  return FlutterBeaconRangingSource();
});

final beaconMonitoringSourceProvider = Provider<BeaconMonitoringSource>((_) {
  return FlutterBeaconMonitoringSource();
});

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final queue = ref.watch(movementQueueProvider);
  return SyncWorker(queue: queue);
});

final connectivityStatusSourceProvider =
    Provider<ConnectivityStatusSource>((_) {
  return ConnectivityPlusStatusSource();
});

final syncPeriodicIntervalProvider = Provider<Duration>((_) {
  return const Duration(minutes: 15);
});

final appRuntimeCoordinatorProvider = Provider<AppRuntimeCoordinator>((ref) {
  final worker = ref.watch(syncWorkerProvider);
  final connectivity = ref.watch(connectivityStatusSourceProvider);
  final interval = ref.watch(syncPeriodicIntervalProvider);
  return AppRuntimeCoordinator(
    syncWorker: worker,
    connectivityChanges: connectivity.onStatusChanged,
    periodicInterval: interval,
  );
});

final permissionsGatewayProvider = Provider<PermissionsGateway>((ref) {
  return ref.watch(defaultPermissionsGatewayProvider);
});

final onboardingWizardProvider = Provider<OnboardingWizard>((ref) {
  final gateway = ref.watch(permissionsGatewayProvider);
  return OnboardingWizard(gateway: gateway);
});

final criticalAlertNotifierProvider = Provider<CriticalAlertNotifier>((ref) {
  return ref.watch(defaultCriticalAlertNotifierProvider);
});

final alertNavigationProvider = Provider<AlertNavigation>((ref) {
  return ProviderAlertNavigation(
    setCurrentMinor: (minor) {
      ref.read(currentMinorProvider.notifier).state = minor;
    },
    requestDashboardNavigation: (minor) {
      ref.read(pendingAlertMinorProvider.notifier).state = minor;
    },
  );
});

final criticalAlertHandlerProvider = Provider<CriticalAlertHandler>((ref) {
  final notifier = ref.watch(criticalAlertNotifierProvider);
  final navigation = ref.watch(alertNavigationProvider);
  return CriticalAlertHandler(notifier: notifier, navigation: navigation);
});

final manualCareServiceProvider = Provider<ManualCareService>((ref) {
  final sink = ref.watch(movementLogSinkProvider);
  return ManualCareService(sink: sink);
});

final nativeSettingsValidatorProvider = Provider<NativeSettingsValidator>((_) {
  return NativeSettingsValidator();
});

final monitoringEnabledProvider = StateProvider<bool>((_) => false);

final dashboardViewModelProvider =
    Provider.family<DashboardViewModel, int?>((ref, currentMinor) {
  final auth = ref.watch(authStateProvider);
  final queue = ref.watch(movementQueueProvider);
  final isMonitoring = ref.watch(monitoringEnabledProvider);
  return DashboardViewModel(
    staffName: auth.staffId ?? 'unknown',
    facilityName: auth.facilityId?.toString() ?? 'unknown',
    currentMinor: currentMinor,
    isMonitoring: isMonitoring,
    unsyncedCount: queue.unsyncedCount(),
  );
});

final currentMinorProvider = StateProvider<int?>((_) => null);

final dashboardRouteViewModelProvider = Provider<DashboardViewModel>((ref) {
  final minor = ref.watch(currentMinorProvider);
  return ref.watch(dashboardViewModelProvider(minor));
});

final pendingAlertMinorProvider = StateProvider<int?>((_) => null);

final defaultPermissionsGatewayProvider = Provider<PermissionsGateway>((_) {
  return PermissionHandlerGateway();
});

final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((_) {
  return FlutterLocalNotificationsPlugin();
});

final localNotificationGatewayProvider =
    Provider<LocalNotificationGateway>((ref) {
  final plugin = ref.watch(flutterLocalNotificationsPluginProvider);
  return FlutterLocalNotificationGateway(plugin: plugin);
});

final alertFeedbackProvider = Provider<AlertFeedback>((_) {
  return SystemAlertFeedback();
});

final defaultCriticalAlertNotifierProvider =
    Provider<CriticalAlertNotifier>((ref) {
  final gateway = ref.watch(localNotificationGatewayProvider);
  final feedback = ref.watch(alertFeedbackProvider);
  return FlutterCriticalAlertNotifier(
    gateway: gateway,
    feedback: feedback,
    now: DateTime.now,
  );
});

final fcmCriticalAlertDispatcherProvider =
    Provider<FcmCriticalAlertDispatcher>((ref) {
  final handler = ref.watch(criticalAlertHandlerProvider);
  return FcmCriticalAlertDispatcher(handler: handler);
});

final firebaseInitializerProvider = Provider<FirebaseInitializer>((_) {
  return const FlutterFirebaseInitializer();
});

final fcmSourceProvider = Provider<FcmSource>((_) {
  return const FirebaseMessagingSource();
});

final appBootstrapProvider = Provider<AppBootstrap>((ref) {
  final firebase = ref.watch(firebaseInitializerProvider);
  final source = ref.watch(fcmSourceProvider);
  final dispatcher = ref.watch(fcmCriticalAlertDispatcherProvider);
  return AppBootstrap(
    firebase: firebase,
    source: source,
    dispatcher: dispatcher,
  );
});

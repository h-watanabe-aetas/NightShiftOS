import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/login_screen.dart';
import '../beacon/beacon_monitoring_source.dart';
import '../domain/auth_state.dart';
import '../domain/beacon_reading.dart';
import '../domain/beacon_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../providers/app_providers.dart';
import '../dashboard/dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  final pendingAlertMinor = ref.watch(pendingAlertMinorProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(
          onCompleted: () {
            final current = ref.read(authStateProvider);
            ref.read(authStateProvider.notifier).state = AuthState(
              staffId: current.staffId,
              facilityId: current.facilityId ?? 1,
            );
            context.go('/dashboard');
          },
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const _DashboardRouteScreen(),
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLogin = location == '/login';
      final isOnboarding = location == '/onboarding';

      if (auth.staffId == null && !isLogin) {
        return '/login';
      }

      if (auth.staffId != null && auth.facilityId == null && !isOnboarding) {
        return '/onboarding';
      }

      if (auth.staffId != null &&
          auth.facilityId != null &&
          (isLogin || isOnboarding)) {
        return '/dashboard';
      }

      if (auth.staffId != null &&
          auth.facilityId != null &&
          pendingAlertMinor != null &&
          location != '/dashboard') {
        return '/dashboard';
      }

      return null;
    },
  );
});

class _DashboardRouteScreen extends ConsumerStatefulWidget {
  const _DashboardRouteScreen();

  @override
  ConsumerState<_DashboardRouteScreen> createState() =>
      _DashboardRouteScreenState();
}

class _DashboardRouteScreenState extends ConsumerState<_DashboardRouteScreen> {
  StreamSubscription<List<BeaconReading>>? _rangingSubscription;
  StreamSubscription<BeaconMonitoringEvent>? _monitoringSubscription;
  int? _subscribedRangingFacilityId;
  int? _subscribedMonitoringFacilityId;

  @override
  void initState() {
    super.initState();
    _ensureRangingSubscription();
  }

  @override
  void dispose() {
    _rangingSubscription?.cancel();
    _monitoringSubscription?.cancel();
    super.dispose();
  }

  void _ensureRangingSubscription() {
    final isMonitoring = ref.read(monitoringEnabledProvider);
    if (!isMonitoring) {
      _rangingSubscription?.cancel();
      _rangingSubscription = null;
      _subscribedRangingFacilityId = null;
      return;
    }

    final facilityId = ref.read(authStateProvider).facilityId;
    if (facilityId == null || facilityId == _subscribedRangingFacilityId) {
      return;
    }

    _rangingSubscription?.cancel();
    _subscribedRangingFacilityId = facilityId;
    final source = ref.read(beaconRangingSourceProvider);
    _rangingSubscription =
        source.watchRanging(facilityId: facilityId).listen((readings) {
      final minor = BeaconService.pickMinor(readings);
      ref.read(currentMinorProvider.notifier).state = minor;
      ref.read(beaconServiceProvider).updateLastKnownMinor(minor);
    });
  }

  void _ensureMonitoringSubscription() {
    final isMonitoring = ref.read(monitoringEnabledProvider);
    if (!isMonitoring) {
      _monitoringSubscription?.cancel();
      _monitoringSubscription = null;
      _subscribedMonitoringFacilityId = null;
      return;
    }

    final facilityId = ref.read(authStateProvider).facilityId;
    if (facilityId == null || facilityId == _subscribedMonitoringFacilityId) {
      return;
    }

    _monitoringSubscription?.cancel();
    _subscribedMonitoringFacilityId = facilityId;
    final source = ref.read(beaconMonitoringSourceProvider);
    _monitoringSubscription =
        source.watchMonitoring(facilityId: facilityId).listen((event) async {
      final auth = ref.read(authStateProvider);
      final staffId = auth.staffId;
      if (staffId == null) {
        return;
      }

      final beaconService = ref.read(beaconServiceProvider);
      final timestamp = DateTime.now().toUtc();
      if (event.type == BeaconMonitoringEventType.enter) {
        final log = beaconService.handleEnterRegion(
          staffId: staffId,
          timestamp: timestamp,
        );
        await ref.read(movementLogSinkProvider).saveLog(log);
      } else if (event.type == BeaconMonitoringEventType.exit) {
        final log = beaconService.handleExitRegion(
          staffId: staffId,
          timestamp: timestamp,
        );
        await ref.read(movementLogSinkProvider).saveLog(log);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensureRangingSubscription();
    _ensureMonitoringSubscription();

    final auth = ref.watch(authStateProvider);
    final viewModel = ref.watch(dashboardRouteViewModelProvider);
    final pendingAlertMinor = ref.watch(pendingAlertMinorProvider);
    if (pendingAlertMinor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(pendingAlertMinorProvider.notifier).state = null;
      });
    }

    return DashboardScreen(
      staffId: auth.staffId ?? 'unknown',
      viewModel: viewModel,
    );
  }
}

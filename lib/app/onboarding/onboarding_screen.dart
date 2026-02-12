import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'permissions_gateway.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.onCompleted});

  final VoidCallback? onCompleted;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _loading = true;
  List<AppPermission> _pending = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
    });
    final wizard = ref.read(onboardingWizardProvider);
    final pending = await wizard.pendingPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _pending = pending;
      _loading = false;
    });
  }

  Future<void> _request(AppPermission permission) async {
    final wizard = ref.read(onboardingWizardProvider);
    await wizard.requestPermission(permission);
    await _refresh();
  }

  String _actionLabel(AppPermission permission) {
    switch (permission) {
      case AppPermission.locationAlways:
        return '位置情報(常時)を許可';
      case AppPermission.notifications:
        return '通知権限を許可';
      case AppPermission.bluetoothScan:
        return 'Bluetooth権限を許可';
    }
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(onboardingWizardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('権限セットアップ'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'NightShift Appは夜勤中の自動記録のために以下の権限が必要です。GPSで利用者や職員を追跡しない設計です。',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ..._pending.map((permission) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wizard.rationale(permission),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            key: Key('request-${permission.name}'),
                            onPressed: () => _request(permission),
                            child: Text(_actionLabel(permission)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_pending.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('必要な権限はすべて許可されています。'),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('complete-onboarding'),
                  onPressed: _pending.isEmpty
                      ? () {
                          widget.onCompleted?.call();
                        }
                      : null,
                  child: const Text('業務開始'),
                ),
              ],
            ),
    );
  }
}

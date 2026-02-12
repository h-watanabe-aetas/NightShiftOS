import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../care/care_action.dart';
import '../providers/app_providers.dart';
import 'dashboard_view_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    required this.staffId,
    required this.viewModel,
  });

  final String staffId;
  final DashboardViewModel viewModel;

  Future<void> _recordCare(
    WidgetRef ref,
    BuildContext context,
    CareAction action,
  ) async {
    final service = ref.read(manualCareServiceProvider);
    await service.recordCare(
      staffId: staffId,
      minor: viewModel.currentMinor,
      action: action,
      timestamp: DateTime.now().toUtc(),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${action.wireAction} を記録しました'),
        ),
      );
    }
  }

  Future<void> _setMonitoring(
    WidgetRef ref,
    BuildContext context,
    bool enabled,
  ) async {
    final auth = ref.read(authStateProvider);
    final beacon = ref.read(beaconServiceProvider);

    try {
      if (enabled) {
        beacon.startMonitoring(auth);
      } else {
        beacon.stopMonitoring();
        ref.read(currentMinorProvider.notifier).state = null;
      }
      ref.read(monitoringEnabledProvider.notifier).state = enabled;

      if (context.mounted) {
        final message = enabled ? '業務開始: 監視を開始しました' : '業務終了: 監視を停止しました';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('監視を開始できません: ${error.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${viewModel.staffName} / ${viewModel.facilityName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.locationLabel,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(viewModel.monitoringLabel),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.queueLabel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: viewModel.shouldHighlightQueue ? Colors.orange : null,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: viewModel.quickActions.map((action) {
                  return ElevatedButton(
                    key: Key('action-${action.name}'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(80),
                    ),
                    onPressed: () => _recordCare(ref, context, action),
                    child: Text(_label(action)),
                  );
                }).toList(growable: false),
              ),
            ),
            SwitchListTile(
              key: const Key('monitoring-toggle'),
              contentPadding: EdgeInsets.zero,
              value: viewModel.isMonitoring,
              title: Text(viewModel.isMonitoring ? '業務終了' : '業務開始'),
              subtitle: Text(viewModel.isMonitoring ? '監視を停止' : '監視を開始'),
              onChanged: (enabled) => _setMonitoring(ref, context, enabled),
            ),
          ],
        ),
      ),
    );
  }

  String _label(CareAction action) {
    switch (action) {
      case CareAction.toilet:
        return 'トイレ';
      case CareAction.posture:
        return '体位交換';
      case CareAction.check:
        return '巡視';
      case CareAction.transfer:
        return '移乗';
      case CareAction.hydration:
        return '水分';
      case CareAction.other:
        return 'その他';
    }
  }
}

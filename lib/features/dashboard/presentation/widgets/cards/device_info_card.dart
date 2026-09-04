import 'package:flutter/material.dart';

import '../../../../../app/di/injection.dart';
import '../../../../../core/platform/native_channels.dart';
import '../dashboard_card_shell.dart';

class DeviceInfoCard extends StatefulWidget {
  const DeviceInfoCard({super.key});

  @override
  State<DeviceInfoCard> createState() => _DeviceInfoCardState();
}

class _DeviceInfoCardState extends State<DeviceInfoCard> {
  late Future<NativeDeviceInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<NativeChannels>().getDeviceInfo();
  }

  void _retry() {
    setState(() => _future = getIt<NativeChannels>().getDeviceInfo());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardCardShell(
      icon: Icons.smartphone_outlined,
      title: 'Device Info',
      child: FutureBuilder<NativeDeviceInfo>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (snapshot.hasError) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    'Native device info unavailable here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Retry',
                  iconSize: 18,
                  icon: const Icon(Icons.refresh),
                  onPressed: _retry,
                ),
              ],
            );
          }

          final info = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(info.modelName, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'OS ${info.osVersion}'
                '${info.batteryPercent >= 0 ? ' · ${info.batteryPercent}% battery' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

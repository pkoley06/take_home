import 'package:flutter/material.dart';

import '../dashboard_card_shell.dart';

class _WeatherSample {
  const _WeatherSample(this.tempCelsius, this.condition, this.icon);

  final int tempCelsius;
  final String condition;
  final IconData icon;
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  static const _samples = [
    _WeatherSample(22, 'Sunny', Icons.wb_sunny_outlined),
    _WeatherSample(18, 'Cloudy', Icons.cloud_outlined),
    _WeatherSample(15, 'Rainy', Icons.water_drop_outlined),
    _WeatherSample(9, 'Windy', Icons.air),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sample = _samples[DateTime.now().day % _samples.length];
    return DashboardCardShell(
      icon: sample.icon,
      title: 'Weather',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${sample.tempCelsius}°C · ${sample.condition}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Mock data, not a live forecast',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

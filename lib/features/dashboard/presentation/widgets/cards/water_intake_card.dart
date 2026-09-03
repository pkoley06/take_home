import 'package:flutter/material.dart';

import '../dashboard_card_shell.dart';

class WaterIntakeCard extends StatefulWidget {
  const WaterIntakeCard({super.key});

  @override
  State<WaterIntakeCard> createState() => _WaterIntakeCardState();
}

class _WaterIntakeCardState extends State<WaterIntakeCard> {
  static const _goal = 8;

  int _glasses = 0;

  void _increment() => setState(() => _glasses = (_glasses + 1).clamp(0, _goal));

  void _decrement() => setState(() => _glasses = (_glasses - 1).clamp(0, _goal));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardCardShell(
      icon: Icons.local_drink_outlined,
      title: 'Water Intake',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_glasses / $_goal glasses', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _glasses / _goal,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton.filledTonal(
                onPressed: _glasses > 0 ? _decrement : null,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _glasses < _goal ? _increment : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key});

  String _greetingFor(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_greetingFor(now.hour), style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMMM d').format(now),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

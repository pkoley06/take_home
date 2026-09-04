import 'package:flutter/material.dart';

import '../dashboard_card_shell.dart';

class TasksSummaryCard extends StatelessWidget {
  const TasksSummaryCard({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardCardShell(
      icon: Icons.checklist_outlined,
      title: "Today's Tasks",
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$count', style: theme.textTheme.displaySmall),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'open checklist items',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

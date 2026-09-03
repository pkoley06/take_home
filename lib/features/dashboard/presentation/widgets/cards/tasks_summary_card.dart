import 'package:flutter/material.dart';

import '../dashboard_card_shell.dart';

class TasksSummaryCard extends StatelessWidget {
  const TasksSummaryCard({super.key});

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
          Text('3', style: theme.textTheme.displaySmall),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'tasks due today',
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

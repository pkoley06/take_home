import 'package:flutter/material.dart';

import '../dashboard_card_shell.dart';

class NotesCountCard extends StatelessWidget {
  const NotesCountCard({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardCardShell(
      icon: Icons.sticky_note_2_outlined,
      title: 'Notes',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$count', style: theme.textTheme.displaySmall),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'saved notes',
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

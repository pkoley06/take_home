import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkedCount = note.checklist.where((item) => item.isChecked).length;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.reminderDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.alarm_outlined,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMMMd().format(note.reminderDate!),
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
              if (note.checklist.isNotEmpty || note.images.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (note.checklist.isNotEmpty) ...[
                      Icon(
                        Icons.checklist_outlined,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$checkedCount/${note.checklist.length}',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (note.images.isNotEmpty) ...[
                      Icon(
                        Icons.image_outlined,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${note.images.length}',
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

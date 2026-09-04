import 'package:flutter/material.dart';

/// A responsive N-column card grid with drag-to-reorder, built on
/// [LongPressDraggable]/[DragTarget] instead of [ReorderableListView] —
/// see the "Dashboard drag-and-reorder" section in architecture-notes.md
/// for why.
class DraggableCardGrid<T> extends StatelessWidget {
  const DraggableCardGrid({
    super.key,
    required this.items,
    required this.columns,
    required this.itemBuilder,
    required this.keyBuilder,
    required this.onReorder,
    this.spacing = 16,
  });

  final List<T> items;
  final int columns;
  final double spacing;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Key Function(T item) keyBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = spacing * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < items.length; index++)
              SizedBox(
                key: keyBuilder(items[index]),
                width: itemWidth,
                child: _DragCell(
                  index: index,
                  width: itemWidth,
                  onAccept: (fromIndex) => onReorder(fromIndex, index),
                  child: itemBuilder(context, items[index]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DragCell extends StatelessWidget {
  const _DragCell({
    required this.index,
    required this.width,
    required this.onAccept,
    required this.child,
  });

  final int index;
  final double width;
  final ValueChanged<int> onAccept;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isTarget = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTarget ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: LongPressDraggable<int>(
            data: index,
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: width,
                child: Opacity(opacity: 0.85, child: child),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: child),
            child: child,
          ),
        );
      },
    );
  }
}

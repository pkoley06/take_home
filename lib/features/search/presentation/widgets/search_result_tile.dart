import 'package:flutter/material.dart';

import '../../domain/entities/search_item.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({super.key, required this.item, required this.query});

  final SearchItem item;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: _highlighted(
        item.title,
        theme.textTheme.bodyLarge ?? const TextStyle(),
        theme.colorScheme.primary,
      ),
      subtitle: _highlighted(
        item.subtitle,
        theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ) ??
            const TextStyle(),
        theme.colorScheme.primary,
      ),
      trailing: Chip(
        label: Text(item.category),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _highlighted(String text, TextStyle baseStyle, Color highlightColor) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    var index = lowerText.indexOf(lowerQuery, start);

    if (index == -1) return Text(text, style: baseStyle);

    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: highlightColor,
          ),
        ),
      );
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

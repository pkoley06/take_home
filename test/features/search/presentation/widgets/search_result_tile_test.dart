import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:take_home/features/search/domain/entities/search_item.dart';
import 'package:take_home/features/search/presentation/widgets/search_result_tile.dart';

void main() {
  testWidgets(
    'highlights every case-insensitive match of the query as a bold TextSpan',
    (tester) async {
      const item = SearchItem(
        id: 1,
        title: 'Milk and Eggs',
        subtitle: 'Grocery list',
        category: 'Note',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchResultTile(item: item, query: 'milk'),
          ),
        ),
      );

      final titleRichText = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere((w) => w.text.toPlainText() == 'Milk and Eggs');
      final titleSpan = titleRichText.text as TextSpan;
      final children = titleSpan.children!.cast<TextSpan>();

      expect(children.map((s) => s.text).toList(), ['Milk', ' and Eggs']);
      expect(children.first.style?.fontWeight, FontWeight.bold);
      expect(children.last.style?.fontWeight, isNot(FontWeight.bold));
    },
  );

  testWidgets('renders plain text with no highlighting when the query does not match', (
    tester,
  ) async {
    const item = SearchItem(
      id: 2,
      title: 'Project Plan',
      subtitle: 'Roadmap',
      category: 'Note',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SearchResultTile(item: item, query: 'zzz')),
      ),
    );

    expect(find.text('Project Plan'), findsOneWidget);
  });
}

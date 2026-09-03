import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.search,
      message: 'Search will live here.',
    );
  }
}

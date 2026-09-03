import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.sticky_note_2_outlined,
      message: 'Your notes will show up here.',
    );
  }
}

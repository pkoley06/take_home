import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.dashboard_outlined,
      message: 'Dashboard cards will live here.',
    );
  }
}

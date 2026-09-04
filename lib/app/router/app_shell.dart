import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/sync/sync_cubit.dart';
import '../../core/widgets/sync_banner.dart';
import '../di/injection.dart';
import '../theme/theme_cubit.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Workspace'),
        actions: [
          if (kDebugMode)
            BlocBuilder<SyncCubit, SyncState>(
              bloc: getIt<SyncCubit>(),
              builder: (context, state) {
                return IconButton(
                  tooltip: state.isOnline
                      ? 'Simulate offline (debug)'
                      : 'Simulate online (debug)',
                  icon: Icon(state.isOnline ? Icons.wifi : Icons.wifi_off),
                  onPressed: () => getIt<SyncCubit>().toggleDebugOffline(),
                );
              },
            ),
          BlocBuilder<ThemeCubit, ThemeState>(
            bloc: getIt<ThemeCubit>(),
            builder: (context, state) {
              final isDark = state.mode == ThemeMode.dark;
              return IconButton(
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => getIt<ThemeCubit>().toggleMode(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}

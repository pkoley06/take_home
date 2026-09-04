import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/di/injection.dart';
import '../sync/sync_cubit.dart';

class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      bloc: getIt<SyncCubit>(),
      builder: (context, state) {
        final theme = Theme.of(context);
        final content = _contentFor(state, theme);

        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: content == null
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  color: content.color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(content.icon, size: 16, color: content.onColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          content.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: content.onColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  _BannerContent? _contentFor(SyncState state, ThemeData theme) {
    if (!state.isOnline) {
      return _BannerContent(
        icon: Icons.cloud_off_outlined,
        message: "Working Offline — changes will sync when you're back online.",
        color: theme.colorScheme.errorContainer,
        onColor: theme.colorScheme.onErrorContainer,
      );
    }
    if (state.isSyncing) {
      final count = state.pendingCount == 0 ? 1 : state.pendingCount;
      return _BannerContent(
        icon: Icons.sync,
        message: 'Syncing $count change${count == 1 ? '' : 's'}...',
        color: theme.colorScheme.secondaryContainer,
        onColor: theme.colorScheme.onSecondaryContainer,
      );
    }
    if (state.justSyncedAt != null) {
      return _BannerContent(
        icon: Icons.cloud_done_outlined,
        message: 'Synced',
        color: theme.colorScheme.primaryContainer,
        onColor: theme.colorScheme.onPrimaryContainer,
      );
    }
    return null;
  }
}

class _BannerContent {
  const _BannerContent({
    required this.icon,
    required this.message,
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color onColor;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../domain/dashboard_defaults.dart';
import '../../domain/entities/dashboard_card_config.dart';
import '../../domain/entities/dashboard_card_type.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/cards/device_info_card.dart';
import '../widgets/cards/focus_timer_card.dart';
import '../widgets/cards/greeting_card.dart';
import '../widgets/cards/notes_count_card.dart';
import '../widgets/cards/tasks_summary_card.dart';
import '../widgets/cards/water_intake_card.dart';
import '../widgets/cards/weather_card.dart';
import '../widgets/dashboard_breakpoints.dart';
import '../widgets/draggable_card_grid.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>.value(
      value: getIt<DashboardBloc>()..add(const DashboardStarted()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          switch (state.status) {
            case DashboardStatus.initial:
            case DashboardStatus.loading:
              return const _DashboardSkeleton();
            case DashboardStatus.error:
              return ErrorState(
                message:
                    state.errorMessage ?? 'Could not load your dashboard.',
                onRetry: () =>
                    context.read<DashboardBloc>().add(const DashboardStarted()),
              );
            case DashboardStatus.loaded:
              return _DashboardGrid(
                cards: state.cards,
                notesCount: state.notesCount,
                pendingTasksCount: state.pendingTasksCount,
              );
          }
        },
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({
    required this.cards,
    required this.notesCount,
    required this.pendingTasksCount,
  });

  final List<DashboardCardConfig> cards;
  final int notesCount;
  final int pendingTasksCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = dashboardColumnsForWidth(constraints.maxWidth);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: DraggableCardGrid<DashboardCardConfig>(
            items: cards,
            columns: columns,
            keyBuilder: (card) => ValueKey(card.type),
            itemBuilder: (context, card) => _buildCard(card.type),
            onReorder: (oldIndex, newIndex) {
              context.read<DashboardBloc>().add(
                DashboardCardsReordered(oldIndex: oldIndex, newIndex: newIndex),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCard(DashboardCardType type) {
    switch (type) {
      case DashboardCardType.greeting:
        return const GreetingCard();
      case DashboardCardType.tasksSummary:
        return TasksSummaryCard(count: pendingTasksCount);
      case DashboardCardType.notesCount:
        return NotesCountCard(count: notesCount);
      case DashboardCardType.weather:
        return const WeatherCard();
      case DashboardCardType.waterIntake:
        return const WaterIntakeCard();
      case DashboardCardType.focusTimer:
        return const FocusTimerCard();
      case DashboardCardType.deviceInfo:
        return const DeviceInfoCard();
    }
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = dashboardColumnsForWidth(constraints.maxWidth);
        final width = constraints.maxWidth;
        final itemWidth = (width - 16 * (columns - 1)) / columns;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final _ in kDefaultDashboardCardOrder)
                SizedBox(
                  width: itemWidth,
                  child: const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: LoadingSkeleton(height: 80),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

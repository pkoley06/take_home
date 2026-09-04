import 'package:equatable/equatable.dart';

import '../../domain/entities/dashboard_card_config.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  const DashboardState({
    required this.status,
    this.cards = const [],
    this.errorMessage,
    this.notesCount = 0,
    this.pendingTasksCount = 0,
  });

  const DashboardState.initial() : this(status: DashboardStatus.initial);

  final DashboardStatus status;
  final List<DashboardCardConfig> cards;
  final String? errorMessage;
  final int notesCount;
  final int pendingTasksCount;

  DashboardState copyWith({
    DashboardStatus? status,
    List<DashboardCardConfig>? cards,
    String? errorMessage,
    int? notesCount,
    int? pendingTasksCount,
  }) {
    return DashboardState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      errorMessage: errorMessage,
      notesCount: notesCount ?? this.notesCount,
      pendingTasksCount: pendingTasksCount ?? this.pendingTasksCount,
    );
  }

  @override
  List<Object?> get props =>
      [status, cards, errorMessage, notesCount, pendingTasksCount];
}

import 'package:equatable/equatable.dart';

import '../../domain/entities/dashboard_card_config.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  const DashboardState({
    required this.status,
    this.cards = const [],
    this.errorMessage,
  });

  const DashboardState.initial() : this(status: DashboardStatus.initial);

  final DashboardStatus status;
  final List<DashboardCardConfig> cards;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    List<DashboardCardConfig>? cards,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, cards, errorMessage];
}

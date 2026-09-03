import 'package:equatable/equatable.dart';

import 'dashboard_card_type.dart';

class DashboardCardConfig extends Equatable {
  const DashboardCardConfig({
    required this.type,
    required this.sortOrder,
    this.isVisible = true,
  });

  final DashboardCardType type;
  final int sortOrder;
  final bool isVisible;

  DashboardCardConfig copyWith({
    DashboardCardType? type,
    int? sortOrder,
    bool? isVisible,
  }) {
    return DashboardCardConfig(
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  List<Object?> get props => [type, sortOrder, isVisible];
}

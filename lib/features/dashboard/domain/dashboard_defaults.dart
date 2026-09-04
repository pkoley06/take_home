import 'entities/dashboard_card_config.dart';
import 'entities/dashboard_card_type.dart';

const List<DashboardCardType> kDefaultDashboardCardOrder = [
  DashboardCardType.greeting,
  DashboardCardType.tasksSummary,
  DashboardCardType.notesCount,
  DashboardCardType.weather,
  DashboardCardType.waterIntake,
  DashboardCardType.focusTimer,
  DashboardCardType.deviceInfo,
];

List<DashboardCardConfig> buildDefaultDashboardCards() {
  return [
    for (var i = 0; i < kDefaultDashboardCardOrder.length; i++)
      DashboardCardConfig(type: kDefaultDashboardCardOrder[i], sortOrder: i),
  ];
}

import '../entities/dashboard_card_config.dart';

abstract class DashboardRepository {
  Future<List<DashboardCardConfig>> loadCards();

  Future<void> persistOrder(List<DashboardCardConfig> cards);
}

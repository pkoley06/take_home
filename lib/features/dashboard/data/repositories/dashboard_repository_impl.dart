import '../../domain/dashboard_defaults.dart';
import '../../domain/entities/dashboard_card_config.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../models/dashboard_card_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._datasource);

  final DashboardLocalDatasource _datasource;

  @override
  Future<List<DashboardCardConfig>> loadCards() async {
    final existing = await _datasource.getCards();
    if (existing.isNotEmpty) return existing;

    final defaults = buildDefaultDashboardCards()
        .map(DashboardCardModel.fromEntity)
        .toList();
    await _datasource.upsertAll(defaults);
    return defaults;
  }

  @override
  Future<void> persistOrder(List<DashboardCardConfig> cards) {
    final models = cards.map(DashboardCardModel.fromEntity).toList();
    return _datasource.upsertAll(models);
  }
}

import '../../../../core/constants/db_constants.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../domain/dashboard_defaults.dart';
import '../../domain/entities/dashboard_card_config.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../models/dashboard_card_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._datasource, this._syncQueue);

  final DashboardLocalDatasource _datasource;
  final SyncQueue _syncQueue;

  @override
  Future<List<DashboardCardConfig>> loadCards() async {
    final existing = await _datasource.getCards();
    if (existing.isEmpty) {
      final defaults = buildDefaultDashboardCards()
          .map(DashboardCardModel.fromEntity)
          .toList();
      await _datasource.upsertAll(defaults);
      return defaults;
    }

    final knownTypes = existing.map((card) => card.type).toSet();
    final missing = [
      for (final type in kDefaultDashboardCardOrder)
        if (!knownTypes.contains(type))
          DashboardCardModel(type: type, sortOrder: existing.length),
    ];
    if (missing.isEmpty) return existing;

    await _datasource.upsertAll(missing);
    return [...existing, ...missing];
  }

  @override
  Future<void> persistOrder(List<DashboardCardConfig> cards) async {
    final models = cards.map(DashboardCardModel.fromEntity).toList();
    await _datasource.upsertAll(models);
    await _syncQueue.enqueue(
      tableName: DbTables.dashboardCards,
      operation: 'reorder',
      payload: {'order': [for (final card in cards) card.type.name]},
    );
  }
}

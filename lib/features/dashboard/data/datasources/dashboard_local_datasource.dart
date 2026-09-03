import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../models/dashboard_card_model.dart';

class DashboardLocalDatasource {
  DashboardLocalDatasource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<DashboardCardModel>> getCards() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      DbTables.dashboardCards,
      orderBy: 'sort_order ASC',
    );
    return rows.map(DashboardCardModel.fromMap).toList();
  }

  Future<void> upsertAll(List<DashboardCardModel> cards) async {
    final db = await _appDatabase.database;
    final batch = db.batch();
    for (final card in cards) {
      batch.insert(
        DbTables.dashboardCards,
        card.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}

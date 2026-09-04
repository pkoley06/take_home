import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../models/search_item_model.dart';

class SearchLocalDatasource {
  SearchLocalDatasource(this._appDatabase);

  final AppDatabase _appDatabase;

  static const int _seedChunkSize = 1000;
  static const int _resultLimit = 250;

  Future<int> count() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DbTables.searchItems}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> insertAll(List<Map<String, Object?>> rows) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      for (var offset = 0; offset < rows.length; offset += _seedChunkSize) {
        final chunk = rows.skip(offset).take(_seedChunkSize);
        final batch = txn.batch();
        for (final row in chunk) {
          batch.insert(DbTables.searchItems, row);
        }
        await batch.commit(noResult: true);
      }
    });
  }

  Future<List<SearchItemModel>> search(String query) async {
    final db = await _appDatabase.database;
    final like = '%$query%';
    final rows = await db.query(
      DbTables.searchItems,
      where: 'title LIKE ? OR subtitle LIKE ?',
      whereArgs: [like, like],
      orderBy: 'title ASC',
      limit: _resultLimit,
    );
    return rows.map(SearchItemModel.fromMap).toList();
  }
}

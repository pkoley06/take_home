import '../../domain/entities/search_item.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_local_datasource.dart';
import '../mock_search_data_generator.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._datasource);

  final SearchLocalDatasource _datasource;

  @override
  Future<void> ensureSeeded() async {
    final existing = await _datasource.count();
    if (existing > 0) return;
    await _datasource.insertAll(generateMockSearchRows());
  }

  @override
  Future<List<SearchItem>> search(String query) => _datasource.search(query);
}

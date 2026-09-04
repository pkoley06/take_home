import '../entities/search_item.dart';

abstract class SearchRepository {
  Future<void> ensureSeeded();

  Future<List<SearchItem>> search(String query);
}

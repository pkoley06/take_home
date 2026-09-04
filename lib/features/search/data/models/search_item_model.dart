import '../../domain/entities/search_item.dart';

class SearchItemModel extends SearchItem {
  const SearchItemModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.category,
  });

  factory SearchItemModel.fromMap(Map<String, Object?> map) {
    return SearchItemModel(
      id: map['id']! as int,
      title: map['title']! as String,
      subtitle: map['subtitle']! as String,
      category: map['category']! as String,
    );
  }
}

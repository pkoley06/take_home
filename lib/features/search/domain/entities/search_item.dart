import 'package:equatable/equatable.dart';

class SearchItem extends Equatable {
  const SearchItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
  });

  final int id;
  final String title;
  final String subtitle;
  final String category;

  @override
  List<Object?> get props => [id, title, subtitle, category];
}

import 'package:equatable/equatable.dart';

import '../../domain/entities/search_item.dart';

enum SearchStatus { initial, loading, loaded, empty, error }

class SearchState extends Equatable {
  const SearchState({
    required this.status,
    this.query = '',
    this.results = const [],
    this.errorMessage,
  });

  const SearchState.initial() : this(status: SearchStatus.loading);

  final SearchStatus status;
  final String query;
  final List<SearchItem> results;
  final String? errorMessage;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<SearchItem>? results,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, query, results, errorMessage];
}

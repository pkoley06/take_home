import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/search_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._repository) : super(const SearchState.initial()) {
    on<SearchStarted>(_onStarted);
    on<SearchQueryChanged>(_onQueryChanged);
  }

  final SearchRepository _repository;

  // Guards against a slower earlier query resolving after a newer one and
  // overwriting its results, in case two queries are ever in flight together.
  String _latestQuery = '';

  Future<void> _onStarted(SearchStarted event, Emitter<SearchState> emit) async {
    try {
      await _repository.ensureSeeded();
      emit(const SearchState(status: SearchStatus.initial));
    } catch (e) {
      emit(
        const SearchState(
          status: SearchStatus.error,
          errorMessage: 'Could not prepare search.',
        ),
      );
    }
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    _latestQuery = query;

    if (query.isEmpty) {
      emit(const SearchState(status: SearchStatus.initial));
      return;
    }

    emit(state.copyWith(status: SearchStatus.loading, query: query));
    try {
      final results = await _repository.search(query);
      if (query != _latestQuery) return;
      emit(
        SearchState(
          status: results.isEmpty ? SearchStatus.empty : SearchStatus.loaded,
          query: query,
          results: results,
        ),
      );
    } catch (e) {
      if (query != _latestQuery) return;
      emit(
        SearchState(
          status: SearchStatus.error,
          query: query,
          errorMessage: 'Search failed. Try again.',
        ),
      );
    }
  }
}

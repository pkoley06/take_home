import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:take_home/features/search/domain/entities/search_item.dart';
import 'package:take_home/features/search/domain/repositories/search_repository.dart';
import 'package:take_home/features/search/presentation/bloc/search_bloc.dart';
import 'package:take_home/features/search/presentation/bloc/search_event.dart';
import 'package:take_home/features/search/presentation/bloc/search_state.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late MockSearchRepository repository;

  setUp(() {
    repository = MockSearchRepository();
  });

  blocTest<SearchBloc, SearchState>(
    'SearchQueryChanged transitions loading -> loaded when results are found',
    build: () {
      when(() => repository.search('milk')).thenAnswer(
        (_) async => const [
          SearchItem(
            id: 1,
            title: 'Milk',
            subtitle: 'Groceries',
            category: 'Note',
          ),
        ],
      );
      return SearchBloc(repository);
    },
    act: (bloc) => bloc.add(const SearchQueryChanged('milk')),
    expect: () => [
      isA<SearchState>()
          .having((s) => s.status, 'status', SearchStatus.loading)
          .having((s) => s.query, 'query', 'milk'),
      isA<SearchState>()
          .having((s) => s.status, 'status', SearchStatus.loaded)
          .having(
            (s) => s.results.single.title,
            'results single title',
            'Milk',
          ),
    ],
  );

  blocTest<SearchBloc, SearchState>(
    'SearchQueryChanged transitions loading -> empty when nothing matches',
    build: () {
      when(() => repository.search('xyz')).thenAnswer((_) async => const []);
      return SearchBloc(repository);
    },
    act: (bloc) => bloc.add(const SearchQueryChanged('xyz')),
    expect: () => [
      isA<SearchState>().having(
        (s) => s.status,
        'status',
        SearchStatus.loading,
      ),
      isA<SearchState>().having(
        (s) => s.status,
        'status',
        SearchStatus.empty,
      ),
    ],
  );
}

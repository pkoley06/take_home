import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/search_result_tile.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchBloc>(
      create: (_) => getIt<SearchBloc>()..add(const SearchStarted()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();
  final Debouncer _debouncer = Debouncer();

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debouncer.run(() {
      if (!mounted) return;
      context.read<SearchBloc>().add(SearchQueryChanged(value));
    });
  }

  Widget _buildBody(BuildContext context, SearchState state) {
    switch (state.status) {
      case SearchStatus.initial:
        return const EmptyState(
          icon: Icons.search,
          message: 'Start typing to search.',
        );
      case SearchStatus.loading:
        return const _SearchSkeleton();
      case SearchStatus.empty:
        return EmptyState(
          icon: Icons.search_off,
          message: 'No results for "${state.query}".',
        );
      case SearchStatus.error:
        return ErrorState(
          message: state.errorMessage ?? 'Search failed.',
          onRetry: () =>
              context.read<SearchBloc>().add(SearchQueryChanged(state.query)),
        );
      case SearchStatus.loaded:
        return ListView.builder(
          itemCount: state.results.length,
          itemBuilder: (context, index) =>
              SearchResultTile(item: state.results[index], query: state.query),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'Search notes, tasks, and more',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onChanged,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(state.status),
                      child: _buildBody(context, state),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: LoadingSkeleton(height: 44),
      ),
    );
  }
}

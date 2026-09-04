import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../notes/domain/repositories/notes_repository.dart';
import '../../domain/entities/dashboard_card_config.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository, this._notesRepository)
    : super(const DashboardState.initial()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardCardsReordered>(_onReordered);
  }

  final DashboardRepository _repository;
  final NotesRepository _notesRepository;

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.status == DashboardStatus.loaded) return;
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final cards = await _repository.loadCards();
      final stats = await _notesRepository.getStats();
      emit(
        state.copyWith(
          status: DashboardStatus.loaded,
          cards: cards,
          notesCount: stats.activeNotesCount,
          pendingTasksCount: stats.pendingChecklistItemsCount,
        ),
      );
    } catch (e) {
      final failure = mapExceptionToFailure(e);
      emit(
        state.copyWith(
          status: DashboardStatus.error,
          errorMessage: failure is UnknownFailure
              ? 'Could not load your dashboard.'
              : failure.message,
        ),
      );
    }
  }

  Future<void> _onReordered(
    DashboardCardsReordered event,
    Emitter<DashboardState> emit,
  ) async {
    final previousCards = state.cards;
    final reordered = List<DashboardCardConfig>.of(state.cards);
    final moved = reordered.removeAt(event.oldIndex);
    reordered.insert(event.newIndex, moved);

    final resequenced = [
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(sortOrder: i),
    ];

    emit(state.copyWith(cards: resequenced));
    try {
      await _repository.persistOrder(resequenced);
    } catch (e) {
      final failure = mapExceptionToFailure(e);
      emit(
        state.copyWith(
          cards: previousCards,
          reorderError: failure is UnknownFailure
              ? 'Could not save the new card order.'
              : failure.message,
        ),
      );
    }
  }
}

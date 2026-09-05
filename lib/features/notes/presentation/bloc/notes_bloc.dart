import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../domain/repositories/notes_repository.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc(this._repository) : super(const NotesState.initial()) {
    on<NotesStarted>(_onStarted);
    on<NoteCreated>(_onCreated);
    on<NoteUpdated>(_onUpdated);
    on<NoteDeleted>(_onDeleted);
    on<NoteArchiveToggled>(_onArchiveToggled);
  }

  final NotesRepository _repository;

  Future<void> _onStarted(NotesStarted event, Emitter<NotesState> emit) async {
    // Re-dispatched after every editor save to pull this (list-scoped) bloc's
    // state back in sync with the editor's own separate bloc instance —
    // only the genuine first load should blank the screen with a skeleton.
    final alreadyLoaded = state.status == NotesStatus.loaded;
    if (!alreadyLoaded) {
      emit(state.copyWith(status: NotesStatus.loading));
      // Local sqlite reads finish in a few ms — without a floor, the
      // skeleton's shimmer never gets a chance to actually read as loading.
      await Future.delayed(const Duration(milliseconds: 500));
    }
    await _reload(emit);
  }

  Future<void> _onCreated(NoteCreated event, Emitter<NotesState> emit) async {
    emit(state.copyWith(submission: SubmissionStatus.inProgress));
    await _mutate(
      emit,
      () => _repository.createNote(
        title: event.title,
        description: event.description,
        checklist: event.checklist,
        imagePaths: event.imagePaths,
        reminderDate: event.reminderDate,
      ),
      failureMessage: 'Could not save your note.',
    );
  }

  Future<void> _onUpdated(NoteUpdated event, Emitter<NotesState> emit) async {
    emit(state.copyWith(submission: SubmissionStatus.inProgress));
    await _mutate(
      emit,
      () => _repository.updateNote(event.note),
      failureMessage: 'Could not save your note.',
    );
  }

  Future<void> _onDeleted(NoteDeleted event, Emitter<NotesState> emit) async {
    emit(state.copyWith(submission: SubmissionStatus.inProgress));
    await _mutate(
      emit,
      () => _repository.deleteNote(event.id),
      failureMessage: 'Could not delete that note.',
    );
  }

  Future<void> _onArchiveToggled(
    NoteArchiveToggled event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(submission: SubmissionStatus.inProgress));
    await _mutate(
      emit,
      () => _repository.setArchived(event.id, event.archive),
      failureMessage: 'Could not update that note.',
    );
  }

  Future<void> _mutate(
    Emitter<NotesState> emit,
    Future<void> Function() action, {
    required String failureMessage,
  }) async {
    try {
      await action();
      await _reload(emit, submission: SubmissionStatus.success);
    } catch (e) {
      final failure = mapExceptionToFailure(e);
      emit(
        state.copyWith(
          submission: SubmissionStatus.failure,
          submissionError: failure is UnknownFailure
              ? failureMessage
              : failure.message,
        ),
      );
    }
  }

  Future<void> _reload(
    Emitter<NotesState> emit, {
    SubmissionStatus? submission,
  }) async {
    try {
      final active = await _repository.getActiveNotes();
      final archived = await _repository.getArchivedNotes();
      emit(
        state.copyWith(
          status: NotesStatus.loaded,
          activeNotes: active,
          archivedNotes: archived,
          submission: submission,
        ),
      );
    } catch (e) {
      final failure = mapExceptionToFailure(e);
      emit(
        state.copyWith(
          status: NotesStatus.error,
          errorMessage: failure is UnknownFailure
              ? 'Could not load your notes.'
              : failure.message,
        ),
      );
    }
  }
}

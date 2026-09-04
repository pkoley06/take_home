import 'package:flutter_bloc/flutter_bloc.dart';

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
    emit(state.copyWith(status: NotesStatus.loading));
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
      emit(
        state.copyWith(
          submission: SubmissionStatus.failure,
          submissionError: failureMessage,
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
      emit(
        state.copyWith(
          status: NotesStatus.error,
          errorMessage: 'Could not load your notes.',
        ),
      );
    }
  }
}

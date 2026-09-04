import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:take_home/features/notes/domain/entities/checklist_item.dart';
import 'package:take_home/features/notes/domain/entities/note.dart';
import 'package:take_home/features/notes/domain/repositories/notes_repository.dart';
import 'package:take_home/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:take_home/features/notes/presentation/bloc/notes_event.dart';
import 'package:take_home/features/notes/presentation/bloc/notes_state.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

Note _note(String id, {String title = 'Untitled'}) {
  final now = DateTime(2026, 1, 1);
  return Note(
    id: id,
    title: title,
    description: '',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockNotesRepository repository;

  setUpAll(() {
    registerFallbackValue(const <ChecklistItem>[]);
    registerFallbackValue(const <String>[]);
  });

  setUp(() {
    repository = MockNotesRepository();
  });

  blocTest<NotesBloc, NotesState>(
    'NoteCreated saves the note and reloads active/archived lists on success',
    build: () {
      when(
        () => repository.createNote(
          title: any(named: 'title'),
          description: any(named: 'description'),
          checklist: any(named: 'checklist'),
          imagePaths: any(named: 'imagePaths'),
          reminderDate: any(named: 'reminderDate'),
        ),
      ).thenAnswer((_) async => _note('n1', title: 'Groceries'));
      when(
        () => repository.getActiveNotes(),
      ).thenAnswer((_) async => [_note('n1', title: 'Groceries')]);
      when(() => repository.getArchivedNotes()).thenAnswer((_) async => []);
      return NotesBloc(repository);
    },
    act: (bloc) =>
        bloc.add(const NoteCreated(title: 'Groceries', description: 'Milk')),
    expect: () => [
      isA<NotesState>().having(
        (s) => s.submission,
        'submission',
        SubmissionStatus.inProgress,
      ),
      isA<NotesState>()
          .having((s) => s.status, 'status', NotesStatus.loaded)
          .having(
            (s) => s.submission,
            'submission',
            SubmissionStatus.success,
          )
          .having(
            (s) => s.activeNotes.single.id,
            'activeNotes single id',
            'n1',
          ),
    ],
    verify: (_) {
      verify(
        () => repository.createNote(
          title: 'Groceries',
          description: 'Milk',
          checklist: const [],
          imagePaths: const [],
          reminderDate: null,
        ),
      ).called(1);
    },
  );

  blocTest<NotesBloc, NotesState>(
    'NoteDeleted removes the note and reloads, dropping it from the active list',
    build: () {
      when(() => repository.deleteNote(any())).thenAnswer((_) async {});
      when(() => repository.getActiveNotes()).thenAnswer((_) async => []);
      when(() => repository.getArchivedNotes()).thenAnswer((_) async => []);
      return NotesBloc(repository);
    },
    act: (bloc) => bloc.add(const NoteDeleted('n1')),
    expect: () => [
      isA<NotesState>().having(
        (s) => s.submission,
        'submission',
        SubmissionStatus.inProgress,
      ),
      isA<NotesState>()
          .having((s) => s.status, 'status', NotesStatus.loaded)
          .having(
            (s) => s.submission,
            'submission',
            SubmissionStatus.success,
          )
          .having((s) => s.activeNotes, 'activeNotes', isEmpty),
    ],
    verify: (_) {
      verify(() => repository.deleteNote('n1')).called(1);
    },
  );
}

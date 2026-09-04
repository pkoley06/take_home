import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:take_home/app/di/injection.dart';
import 'package:take_home/features/notes/domain/repositories/notes_repository.dart';
import 'package:take_home/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:take_home/features/notes/presentation/pages/notes_page.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  late MockNotesRepository repository;

  setUp(() async {
    await getIt.reset();
    repository = MockNotesRepository();
    when(() => repository.getActiveNotes()).thenAnswer((_) async => []);
    when(() => repository.getArchivedNotes()).thenAnswer((_) async => []);
    getIt.registerFactory<NotesBloc>(() => NotesBloc(repository));
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('shows the empty-state message when the active notes list is empty', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NotesPage()));
    await tester.pumpAndSettle();

    expect(find.text('Your notes will show up here.'), findsOneWidget);
  });
}

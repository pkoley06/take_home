import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:take_home/core/database/app_database.dart';
import 'package:take_home/core/notifications/notification_service.dart';
import 'package:take_home/core/sync/sync_queue.dart';
import 'package:take_home/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:take_home/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:take_home/features/notes/domain/entities/checklist_item.dart';

void main() {
  late AppDatabase appDatabase;
  late NotesRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Each test gets a fresh file-backed sqlite db (via sqflite_common_ffi)
    // at the same path AppDatabase always opens, so nothing bleeds between
    // tests even though the schema lives in a private `_onCreate`.
    final dbPath = join(
      await databaseFactory.getDatabasesPath(),
      'smart_workspace.db',
    );
    await databaseFactory.deleteDatabase(dbPath);

    appDatabase = AppDatabase();
    repository = NotesRepositoryImpl(
      NotesLocalDatasource(appDatabase),
      SyncQueue(appDatabase),
      NotificationService(),
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test(
    'createNote persists a note (with checklist) that is retrievable and then deletable',
    () async {
      final note = await repository.createNote(
        title: 'Groceries',
        description: 'Buy milk',
        checklist: const [ChecklistItem(id: 'c1', label: 'Milk')],
      );

      final active = await repository.getActiveNotes();
      expect(active, hasLength(1));
      expect(active.single.title, 'Groceries');
      expect(active.single.checklist.single.label, 'Milk');

      await repository.deleteNote(note.id);
      expect(await repository.getActiveNotes(), isEmpty);
    },
  );

  test(
    'setArchived moves a note between the active/archived lists and getStats reflects it',
    () async {
      final note = await repository.createNote(
        title: 'Trip plan',
        description: '',
        checklist: const [
          ChecklistItem(id: 'c1', label: 'Book flight'),
          ChecklistItem(id: 'c2', label: 'Pack bag', isChecked: true),
        ],
      );

      var stats = await repository.getStats();
      expect(stats.activeNotesCount, 1);
      expect(stats.pendingChecklistItemsCount, 1);

      await repository.setArchived(note.id, true);
      expect(await repository.getActiveNotes(), isEmpty);
      expect((await repository.getArchivedNotes()).single.id, note.id);

      stats = await repository.getStats();
      expect(stats.activeNotesCount, 0);
      expect(stats.pendingChecklistItemsCount, 0);

      await repository.setArchived(note.id, false);
      expect((await repository.getActiveNotes()).single.id, note.id);
    },
  );
}

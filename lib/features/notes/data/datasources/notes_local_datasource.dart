import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../models/checklist_item_model.dart';
import '../models/note_image_model.dart';
import '../models/note_model.dart';

class NotesLocalDatasource {
  NotesLocalDatasource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<NoteModel>> getNotes({required bool archived}) async {
    final db = await _appDatabase.database;
    final noteRows = await db.query(
      DbTables.notes,
      where: 'is_archived = ?',
      whereArgs: [archived ? 1 : 0],
      orderBy: 'updated_at DESC',
    );
    if (noteRows.isEmpty) return const [];

    final noteIds = [for (final row in noteRows) row['id']! as String];
    final checklistByNote = await _checklistByNoteId(db, noteIds);
    final imagesByNote = await _imagesByNoteId(db, noteIds);

    return [
      for (final row in noteRows)
        NoteModel.fromRow(
          row,
          checklist: checklistByNote[row['id']] ?? const [],
          images: imagesByNote[row['id']] ?? const [],
        ),
    ];
  }

  Future<Map<String, List<ChecklistItemModel>>> _checklistByNoteId(
    DatabaseExecutor db,
    List<String> noteIds,
  ) async {
    final placeholders = List.filled(noteIds.length, '?').join(',');
    final rows = await db.query(
      DbTables.checklistItems,
      where: 'note_id IN ($placeholders)',
      whereArgs: noteIds,
      orderBy: 'sort_order ASC',
    );
    final grouped = <String, List<ChecklistItemModel>>{};
    for (final row in rows) {
      final noteId = row['note_id']! as String;
      grouped
          .putIfAbsent(noteId, () => [])
          .add(ChecklistItemModel.fromMap(row));
    }
    return grouped;
  }

  Future<Map<String, List<NoteImageModel>>> _imagesByNoteId(
    DatabaseExecutor db,
    List<String> noteIds,
  ) async {
    final placeholders = List.filled(noteIds.length, '?').join(',');
    final rows = await db.query(
      DbTables.noteImages,
      where: 'note_id IN ($placeholders)',
      whereArgs: noteIds,
      orderBy: 'created_at ASC',
    );
    final grouped = <String, List<NoteImageModel>>{};
    for (final row in rows) {
      final noteId = row['note_id']! as String;
      grouped.putIfAbsent(noteId, () => []).add(NoteImageModel.fromMap(row));
    }
    return grouped;
  }

  Future<void> saveNote(NoteModel note) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.insert(
        DbTables.notes,
        note.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        DbTables.checklistItems,
        where: 'note_id = ?',
        whereArgs: [note.id],
      );
      final checklistBatch = txn.batch();
      for (final item in note.checklist) {
        checklistBatch.insert(
          DbTables.checklistItems,
          ChecklistItemModel.fromEntity(item).toMap(note.id),
        );
      }
      await checklistBatch.commit(noResult: true);

      await txn.delete(
        DbTables.noteImages,
        where: 'note_id = ?',
        whereArgs: [note.id],
      );
      final imageBatch = txn.batch();
      for (final image in note.images) {
        imageBatch.insert(
          DbTables.noteImages,
          NoteImageModel.fromEntity(image).toMap(note.id),
        );
      }
      await imageBatch.commit(noResult: true);
    });
  }

  Future<void> deleteNote(String id) async {
    final db = await _appDatabase.database;
    await db.delete(DbTables.notes, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setArchived(String id, bool isArchived) async {
    final db = await _appDatabase.database;
    await db.update(
      DbTables.notes,
      {
        'is_archived': isArchived ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countActiveNotes() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DbTables.notes} WHERE is_archived = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countPendingChecklistItems() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM ${DbTables.checklistItems} ci
      INNER JOIN ${DbTables.notes} n ON n.id = ci.note_id
      WHERE ci.is_checked = 0 AND n.is_archived = 0
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

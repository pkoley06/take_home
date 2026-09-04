import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/notes_stats.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/notes_local_datasource.dart';
import '../models/note_image_model.dart';
import '../models/note_model.dart';

class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl(this._datasource);

  final NotesLocalDatasource _datasource;

  @override
  Future<List<Note>> getActiveNotes() => _datasource.getNotes(archived: false);

  @override
  Future<List<Note>> getArchivedNotes() => _datasource.getNotes(archived: true);

  @override
  Future<Note> createNote({
    required String title,
    required String description,
    List<ChecklistItem> checklist = const [],
    List<String> imagePaths = const [],
  }) async {
    final now = DateTime.now();
    final note = NoteModel(
      id: generateId(),
      title: title,
      description: description,
      checklist: checklist,
      images: [
        for (final path in imagePaths)
          NoteImageModel(id: generateId(), filePath: path, createdAt: now),
      ],
      createdAt: now,
      updatedAt: now,
    );
    await _datasource.saveNote(note);
    return note;
  }

  @override
  Future<Note> updateNote(Note note) async {
    final updated = NoteModel.fromEntity(note.copyWith(updatedAt: DateTime.now()));
    await _datasource.saveNote(updated);
    return updated;
  }

  @override
  Future<void> deleteNote(String id) => _datasource.deleteNote(id);

  @override
  Future<void> setArchived(String id, bool isArchived) =>
      _datasource.setArchived(id, isArchived);

  @override
  Future<NotesStats> getStats() async {
    final activeCount = await _datasource.countActiveNotes();
    final pendingCount = await _datasource.countPendingChecklistItems();
    return NotesStats(
      activeNotesCount: activeCount,
      pendingChecklistItemsCount: pendingCount,
    );
  }
}

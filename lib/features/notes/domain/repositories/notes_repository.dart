import '../entities/checklist_item.dart';
import '../entities/note.dart';
import '../entities/notes_stats.dart';

abstract class NotesRepository {
  Future<List<Note>> getActiveNotes();

  Future<List<Note>> getArchivedNotes();

  Future<Note> createNote({
    required String title,
    required String description,
    List<ChecklistItem> checklist = const [],
    List<String> imagePaths = const [],
    DateTime? reminderDate,
  });

  Future<Note> updateNote(Note note);

  Future<void> deleteNote(String id);

  Future<void> setArchived(String id, bool isArchived);

  Future<NotesStats> getStats();
}

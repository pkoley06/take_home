import '../../../../core/constants/db_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/notes_stats.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/notes_local_datasource.dart';
import '../models/note_image_model.dart';
import '../models/note_model.dart';

class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl(this._datasource, this._syncQueue, this._notifications);

  final NotesLocalDatasource _datasource;
  final SyncQueue _syncQueue;
  final NotificationService _notifications;

  Future<void> _syncReminder(NoteModel note) {
    final reminderDate = note.reminderDate;
    if (reminderDate == null) {
      return _notifications.cancelNoteReminder(note.id);
    }
    return _notifications.scheduleNoteReminder(
      noteId: note.id,
      noteTitle: note.title,
      date: reminderDate,
    );
  }

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
    DateTime? reminderDate,
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
      reminderDate: reminderDate,
      createdAt: now,
      updatedAt: now,
    );
    await _datasource.saveNote(note);
    await _syncQueue.enqueue(
      tableName: DbTables.notes,
      operation: 'create',
      payload: {'id': note.id},
    );
    await _syncReminder(note);
    return note;
  }

  @override
  Future<Note> updateNote(Note note) async {
    final updated = NoteModel.fromEntity(note.copyWith(updatedAt: DateTime.now()));
    await _datasource.saveNote(updated);
    await _syncQueue.enqueue(
      tableName: DbTables.notes,
      operation: 'update',
      payload: {'id': updated.id},
    );
    await _syncReminder(updated);
    return updated;
  }

  @override
  Future<void> deleteNote(String id) async {
    await _datasource.deleteNote(id);
    await _syncQueue.enqueue(
      tableName: DbTables.notes,
      operation: 'delete',
      payload: {'id': id},
    );
    await _notifications.cancelNoteReminder(id);
  }

  @override
  Future<void> setArchived(String id, bool isArchived) async {
    await _datasource.setArchived(id, isArchived);
    await _syncQueue.enqueue(
      tableName: DbTables.notes,
      operation: isArchived ? 'archive' : 'unarchive',
      payload: {'id': id},
    );
  }

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

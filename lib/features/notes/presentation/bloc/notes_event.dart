import 'package:equatable/equatable.dart';

import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/note.dart';

sealed class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

class NotesStarted extends NotesEvent {
  const NotesStarted();
}

class NoteCreated extends NotesEvent {
  const NoteCreated({
    required this.title,
    required this.description,
    this.checklist = const [],
    this.imagePaths = const [],
    this.reminderDate,
  });

  final String title;
  final String description;
  final List<ChecklistItem> checklist;
  final List<String> imagePaths;
  final DateTime? reminderDate;

  @override
  List<Object?> get props =>
      [title, description, checklist, imagePaths, reminderDate];
}

class NoteUpdated extends NotesEvent {
  const NoteUpdated(this.note);

  final Note note;

  @override
  List<Object?> get props => [note];
}

class NoteDeleted extends NotesEvent {
  const NoteDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class NoteArchiveToggled extends NotesEvent {
  const NoteArchiveToggled({required this.id, required this.archive});

  final String id;
  final bool archive;

  @override
  List<Object?> get props => [id, archive];
}

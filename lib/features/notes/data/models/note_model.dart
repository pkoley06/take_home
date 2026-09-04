import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_image.dart';

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.title,
    required super.description,
    super.checklist,
    super.images,
    super.isArchived,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      description: note.description,
      checklist: note.checklist,
      images: note.images,
      isArchived: note.isArchived,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
  }

  factory NoteModel.fromRow(
    Map<String, Object?> row, {
    List<ChecklistItem> checklist = const [],
    List<NoteImage> images = const [],
  }) {
    return NoteModel(
      id: row['id']! as String,
      title: row['title']! as String,
      description: row['description']! as String,
      checklist: checklist,
      images: images,
      isArchived: (row['is_archived']! as int) == 1,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

import '../../domain/entities/note_image.dart';

class NoteImageModel extends NoteImage {
  const NoteImageModel({
    required super.id,
    required super.filePath,
    required super.createdAt,
  });

  factory NoteImageModel.fromEntity(NoteImage image) {
    return NoteImageModel(
      id: image.id,
      filePath: image.filePath,
      createdAt: image.createdAt,
    );
  }

  factory NoteImageModel.fromMap(Map<String, Object?> map) {
    return NoteImageModel(
      id: map['id']! as String,
      filePath: map['file_path']! as String,
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }

  Map<String, Object?> toMap(String noteId) {
    return {
      'id': id,
      'note_id': noteId,
      'file_path': filePath,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

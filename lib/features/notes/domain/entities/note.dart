import 'package:equatable/equatable.dart';

import 'checklist_item.dart';
import 'note_image.dart';

class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    required this.description,
    this.checklist = const [],
    this.images = const [],
    this.isArchived = false,
    this.reminderDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final List<ChecklistItem> checklist;
  final List<NoteImage> images;
  final bool isArchived;
  final DateTime? reminderDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({
    String? title,
    String? description,
    List<ChecklistItem>? checklist,
    List<NoteImage>? images,
    bool? isArchived,
    DateTime? updatedAt,
    DateTime? reminderDate,
    bool clearReminderDate = false,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      checklist: checklist ?? this.checklist,
      images: images ?? this.images,
      isArchived: isArchived ?? this.isArchived,
      reminderDate: clearReminderDate
          ? null
          : (reminderDate ?? this.reminderDate),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    checklist,
    images,
    isArchived,
    reminderDate,
    createdAt,
    updatedAt,
  ];
}

import '../../domain/entities/checklist_item.dart';

class ChecklistItemModel extends ChecklistItem {
  const ChecklistItemModel({
    required super.id,
    required super.label,
    super.isChecked,
    super.sortOrder,
  });

  factory ChecklistItemModel.fromEntity(ChecklistItem item) {
    return ChecklistItemModel(
      id: item.id,
      label: item.label,
      isChecked: item.isChecked,
      sortOrder: item.sortOrder,
    );
  }

  factory ChecklistItemModel.fromMap(Map<String, Object?> map) {
    return ChecklistItemModel(
      id: map['id']! as String,
      label: map['label']! as String,
      isChecked: (map['is_checked']! as int) == 1,
      sortOrder: map['sort_order']! as int,
    );
  }

  Map<String, Object?> toMap(String noteId) {
    return {
      'id': id,
      'note_id': noteId,
      'label': label,
      'is_checked': isChecked ? 1 : 0,
      'sort_order': sortOrder,
    };
  }
}

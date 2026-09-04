import 'package:equatable/equatable.dart';

class ChecklistItem extends Equatable {
  const ChecklistItem({
    required this.id,
    required this.label,
    this.isChecked = false,
    this.sortOrder = 0,
  });

  final String id;
  final String label;
  final bool isChecked;
  final int sortOrder;

  ChecklistItem copyWith({String? label, bool? isChecked, int? sortOrder}) {
    return ChecklistItem(
      id: id,
      label: label ?? this.label,
      isChecked: isChecked ?? this.isChecked,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [id, label, isChecked, sortOrder];
}

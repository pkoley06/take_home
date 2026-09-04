import 'package:equatable/equatable.dart';

class NotesStats extends Equatable {
  const NotesStats({
    this.activeNotesCount = 0,
    this.pendingChecklistItemsCount = 0,
  });

  final int activeNotesCount;
  final int pendingChecklistItemsCount;

  @override
  List<Object?> get props => [activeNotesCount, pendingChecklistItemsCount];
}

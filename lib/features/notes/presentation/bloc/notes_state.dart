import 'package:equatable/equatable.dart';

import '../../domain/entities/note.dart';

enum NotesStatus { initial, loading, loaded, error }

enum SubmissionStatus { idle, inProgress, success, failure }

class NotesState extends Equatable {
  const NotesState({
    required this.status,
    this.activeNotes = const [],
    this.archivedNotes = const [],
    this.errorMessage,
    this.submission = SubmissionStatus.idle,
    this.submissionError,
  });

  const NotesState.initial() : this(status: NotesStatus.initial);

  final NotesStatus status;
  final List<Note> activeNotes;
  final List<Note> archivedNotes;
  final String? errorMessage;
  final SubmissionStatus submission;
  final String? submissionError;

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? activeNotes,
    List<Note>? archivedNotes,
    String? errorMessage,
    SubmissionStatus? submission,
    String? submissionError,
  }) {
    return NotesState(
      status: status ?? this.status,
      activeNotes: activeNotes ?? this.activeNotes,
      archivedNotes: archivedNotes ?? this.archivedNotes,
      errorMessage: errorMessage,
      submission: submission ?? this.submission,
      submissionError: submissionError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeNotes,
        archivedNotes,
        errorMessage,
        submission,
        submissionError,
      ];
}

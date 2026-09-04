import 'package:equatable/equatable.dart';

class NoteImage extends Equatable {
  const NoteImage({
    required this.id,
    required this.filePath,
    required this.createdAt,
  });

  final String id;
  final String filePath;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, filePath, createdAt];
}

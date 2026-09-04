import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_image.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';

class NoteEditorPage extends StatelessWidget {
  const NoteEditorPage({super.key, this.note});

  final Note? note;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotesBloc>(
      create: (_) => getIt<NotesBloc>(),
      child: _NoteEditorView(note: note),
    );
  }
}

class _NoteEditorView extends StatefulWidget {
  const _NoteEditorView({this.note});

  final Note? note;

  @override
  State<_NoteEditorView> createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends State<_NoteEditorView> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final TextEditingController _newItemController = TextEditingController();

  late List<ChecklistItem> _checklist;
  late List<NoteImage> _images;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.note?.description ?? '',
    );
    _checklist = List.of(widget.note?.checklist ?? const []);
    _images = List.of(widget.note?.images ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newItemController.dispose();
    super.dispose();
  }

  void _addChecklistItem() {
    final label = _newItemController.text.trim();
    if (label.isEmpty) return;
    setState(() {
      _checklist = [
        ..._checklist,
        ChecklistItem(
          id: generateId(),
          label: label,
          sortOrder: _checklist.length,
        ),
      ];
      _newItemController.clear();
    });
  }

  void _toggleChecklistItem(ChecklistItem item, bool? checked) {
    setState(() {
      _checklist = [
        for (final existing in _checklist)
          if (existing.id == item.id)
            existing.copyWith(isChecked: checked ?? false)
          else
            existing,
      ];
    });
  }

  void _removeChecklistItem(ChecklistItem item) {
    setState(() {
      _checklist = _checklist.where((existing) => existing.id != item.id).toList();
    });
  }

  void _addStubImage() {
    setState(() {
      _images = [
        ..._images,
        NoteImage(
          id: generateId(),
          filePath: 'stub://picked-${generateId()}.jpg',
          createdAt: DateTime.now(),
        ),
      ];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Image picker wiring lands in a later module — this is a placeholder attachment.',
        ),
      ),
    );
  }

  void _removeImage(NoteImage image) {
    setState(() {
      _images = _images.where((existing) => existing.id != image.id).toList();
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your note a title first.')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    final resequencedChecklist = [
      for (var i = 0; i < _checklist.length; i++)
        _checklist[i].copyWith(sortOrder: i),
    ];

    final bloc = context.read<NotesBloc>();
    final existing = widget.note;
    if (existing == null) {
      bloc.add(
        NoteCreated(
          title: title,
          description: description,
          checklist: resequencedChecklist,
          imagePaths: [for (final image in _images) image.filePath],
        ),
      );
    } else {
      bloc.add(
        NoteUpdated(
          existing.copyWith(
            title: title,
            description: description,
            checklist: resequencedChecklist,
            images: _images,
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<NotesBloc>().add(NoteDeleted(widget.note!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotesBloc, NotesState>(
      listenWhen: (previous, current) => previous.submission != current.submission,
      listener: (context, state) {
        if (state.submission == SubmissionStatus.success) {
          Navigator.of(context).pop(true);
        } else if (state.submission == SubmissionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.submissionError ?? 'Something went wrong.'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Note' : 'New Note'),
          actions: [
            if (_isEditing) ...[
              IconButton(
                tooltip: widget.note!.isArchived ? 'Unarchive' : 'Archive',
                icon: Icon(
                  widget.note!.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                onPressed: () => context.read<NotesBloc>().add(
                      NoteArchiveToggled(
                        id: widget.note!.id,
                        archive: !widget.note!.isArchived,
                      ),
                    ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: _confirmDelete,
              ),
            ],
            IconButton(
              tooltip: 'Save',
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const Divider(),
            TextField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Description',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text('Checklist', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final item in _checklist)
              CheckboxListTile(
                key: ValueKey(item.id),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: item.isChecked,
                onChanged: (checked) => _toggleChecklistItem(item, checked),
                title: Text(
                  item.label,
                  style: item.isChecked
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                secondary: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeChecklistItem(item),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newItemController,
                    decoration: const InputDecoration(
                      hintText: 'Add checklist item',
                    ),
                    onSubmitted: (_) => _addChecklistItem(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addChecklistItem,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Images', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final image in _images)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _ImageThumbnail(
                        image: image,
                        onRemove: () => _removeImage(image),
                      ),
                    ),
                  InkWell(
                    onTap: _addStubImage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.image, required this.onRemove});

  final NoteImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final file = File(image.filePath);
    final exists = file.existsSync();

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: exists
                ? Image.file(
                    file,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    cacheWidth: 176,
                  )
                : Container(
                    width: 88,
                    height: 88,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_outlined,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.black54,
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/platform/native_channels.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_image.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../widgets/note_card.dart' show noteHeroTag;

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
  DateTime? _reminderDate;
  String? _titleError;
  String? _checklistItemError;

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
    _reminderDate = widget.note?.reminderDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newItemController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _addChecklistItem() {
    final label = _newItemController.text.trim();
    if (label.isEmpty) {
      setState(() => _checklistItemError = 'Enter an item first.');
      return;
    }
    setState(() {
      _checklistItemError = null;
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
      _checklist = _checklist
          .where((existing) => existing.id != item.id)
          .toList();
    });
  }

  Future<void> _pickReminderDate() async {
    try {
      final picked = await getIt<NativeChannels>().pickDate(
        initialDate: _reminderDate,
      );
      if (picked != null && mounted) {
        setState(() => _reminderDate = picked);
      }
    } on NativeChannelUnavailableException catch (_) {
      _showSnackBar("Couldn't open the date picker.");
    }
  }

  void _clearReminderDate() {
    setState(() => _reminderDate = null);
  }

  Future<void> _addImage() async {
    NativeSheetOption? option;
    try {
      option = await getIt<NativeChannels>().showNativeOptionsSheet();
    } on NativeChannelUnavailableException catch (_) {
      _showSnackBar("Couldn't open the attachment options.");
      return;
    }
    if (option == null || !mounted) return; // user dismissed the sheet

    switch (option) {
      case NativeSheetOption.camera:
        await _pickImage(ImageSource.camera);
      case NativeSheetOption.gallery:
        await _pickImage(ImageSource.gallery);
      case NativeSheetOption.filePicker:
        await _pickPdf();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showSnackBar('Camera permission was denied.');
        return;
      }
    }
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return; // user cancelled the picker
      _appendAttachment(picked.path);
    } on PlatformException catch (e) {
      _showSnackBar(
        e.message ??
            (source == ImageSource.camera
                ? "Couldn't open the camera."
                : "Couldn't open the gallery."),
      );
    }
  }

  Future<void> _pickPdf() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      final path = picked?.path;
      if (path == null || !mounted) return; // user cancelled the picker
      _appendAttachment(path);
    } on PlatformException catch (_) {
      _showSnackBar("Couldn't open the file picker.");
    }
  }

  void _appendAttachment(String path) {
    setState(() {
      _images = [
        ..._images,
        NoteImage(id: generateId(), filePath: path, createdAt: DateTime.now()),
      ];
    });
  }

  void _removeImage(NoteImage image) {
    setState(() {
      _images = _images.where((existing) => existing.id != image.id).toList();
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Give your note a title first.');
      return;
    }
    if (_titleError != null) setState(() => _titleError = null);

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
          reminderDate: _reminderDate,
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
            reminderDate: _reminderDate,
            clearReminderDate: _reminderDate == null,
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

  // A note card in the list becomes this block on open (and back again on
  // save/close) via a matching Hero tag — only meaningful for an existing
  // note, since a new one has no list tile to fly from.
  Widget _buildTitleAndDescription(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _titleController,
          style: theme.textTheme.titleLarge,
          decoration: InputDecoration(
            hintText: 'Title',
            border: InputBorder.none,
            errorText: _titleError,
          ),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
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
      ],
    );

    final existing = widget.note;
    if (existing == null) return content;

    return Hero(
      tag: noteHeroTag(existing.id),
      // A TextField's EditableText can't safely fly mid-transition (its
      // focus/text-input connection doesn't survive being briefly detached
      // into the Overlay), so the shuttle renders a static title preview
      // instead of the real field — the field is back and interactive the
      // instant the flight lands.
      flightShuttleBuilder: (_, _, _, _, _) => Material(
        type: MaterialType.card,
        color: theme.cardColor,
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            existing.title.isEmpty ? 'Untitled' : existing.title,
            style: theme.textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      child: Material(
        type: MaterialType.card,
        color: theme.cardColor,
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.all(12), child: content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotesBloc, NotesState>(
      listenWhen: (previous, current) =>
          previous.submission != current.submission,
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
            _buildTitleAndDescription(context),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm_outlined),
              title: Text(
                _reminderDate == null
                    ? 'Remind me'
                    : DateFormat.yMMMd().format(_reminderDate!),
              ),
              subtitle: _reminderDate == null
                  ? const Text('Uses the native date picker')
                  : null,
              trailing: _reminderDate == null
                  ? null
                  : IconButton(
                      tooltip: 'Clear reminder',
                      icon: const Icon(Icons.close),
                      onPressed: _clearReminderDate,
                    ),
              onTap: _pickReminderDate,
            ),
            const SizedBox(height: 8),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _newItemController,
                    decoration: InputDecoration(
                      hintText: 'Add checklist item',
                      errorText: _checklistItemError,
                    ),
                    onChanged: (_) {
                      if (_checklistItemError != null) {
                        setState(() => _checklistItemError = null);
                      }
                    },
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
                      child: _AttachmentThumbnail(
                        image: image,
                        onRemove: () => _removeImage(image),
                      ),
                    ),
                  InkWell(
                    onTap: _addImage,
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

class _AttachmentThumbnail extends StatelessWidget {
  const _AttachmentThumbnail({required this.image, required this.onRemove});

  final NoteImage image;
  final VoidCallback onRemove;

  bool get _isPdf => image.filePath.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    final file = File(image.filePath);
    final exists = file.existsSync();
    final theme = Theme.of(context);

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isPdf
                ? _PdfCard(file: file, exists: exists)
                : exists
                ? Image.file(
                    file,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    cacheWidth: 176,
                  )
                : _MissingFileCard(theme: theme),
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

class _PdfCard extends StatelessWidget {
  const _PdfCard({required this.file, required this.exists});

  final File file;
  final bool exists;

  String get _fileName => file.uri.pathSegments.last;

  // Guards against a TOCTOU race where the file is deleted between the
  // existsSync() check above and this read — lengthSync() would otherwise
  // throw a FileSystemException straight out of build().
  String? get _sizeLabel {
    if (!exists) return null;
    try {
      final kb = file.lengthSync() / 1024;
      return kb < 1024
          ? '${kb.toStringAsFixed(0)} KB'
          : '${(kb / 1024).toStringAsFixed(1)} MB';
    } on FileSystemException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!exists) return _MissingFileCard(theme: theme, fileName: _fileName);

    final sizeLabel = _sizeLabel;
    return Container(
      width: 88,
      height: 88,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.outline),
          const SizedBox(height: 4),
          Text(
            _fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
          if (sizeLabel != null)
            Text(
              sizeLabel,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
            ),
        ],
      ),
    );
  }
}

/// Shown in place of a thumbnail/PDF card when the file behind a note
/// attachment has been moved or deleted since it was picked — a clear
/// "this is gone" message instead of a crash or a mysterious blank tile.
class _MissingFileCard extends StatelessWidget {
  const _MissingFileCard({required this.theme, this.fileName});

  final ThemeData theme;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: theme.colorScheme.error),
          const SizedBox(height: 4),
          Text(
            'Missing file',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

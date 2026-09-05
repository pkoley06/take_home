import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/constants/route_paths.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../domain/entities/note.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../widgets/note_card.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotesBloc>(
      create: (_) => getIt<NotesBloc>()..add(const NotesStarted()),
      child: const _NotesView(),
    );
  }
}

class _NotesView extends StatefulWidget {
  const _NotesView();

  @override
  State<_NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<_NotesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openEditor(BuildContext context, {Note? note}) async {
    final bloc = context.read<NotesBloc>();
    final saved = await context.push<bool>(RoutePaths.noteEditor, extra: note);
    if (saved == true) {
      bloc.add(const NotesStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotesBloc, NotesState>(
      listenWhen: (previous, current) =>
          current.submission == SubmissionStatus.failure &&
          previous.submission != SubmissionStatus.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.submissionError ?? 'Something went wrong.'),
          ),
        );
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openEditor(context),
          tooltip: 'New note',
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Archived'),
                ],
              ),
              Expanded(
                child: BlocBuilder<NotesBloc, NotesState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case NotesStatus.initial:
                      case NotesStatus.loading:
                        return const _NotesSkeleton();
                      case NotesStatus.error:
                        return ErrorState(
                          message:
                              state.errorMessage ??
                              'Could not load your notes.',
                          onRetry: () => context.read<NotesBloc>().add(
                            const NotesStarted(),
                          ),
                        );
                      case NotesStatus.loaded:
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _NotesGrid(
                              notes: state.activeNotes,
                              emptyMessage: 'Your notes will show up here.',
                              onTap: (note) => _openEditor(context, note: note),
                              archiveIcon: Icons.archive_outlined,
                              archiveTooltip: 'Archive',
                              onArchive: (note) =>
                                  context.read<NotesBloc>().add(
                                    NoteArchiveToggled(
                                      id: note.id,
                                      archive: true,
                                    ),
                                  ),
                              onDelete: (note) => context.read<NotesBloc>().add(
                                NoteDeleted(note.id),
                              ),
                            ),
                            _NotesGrid(
                              notes: state.archivedNotes,
                              emptyMessage: 'No archived notes yet.',
                              onTap: (note) => _openEditor(context, note: note),
                              archiveIcon: Icons.unarchive_outlined,
                              archiveTooltip: 'Unarchive',
                              onArchive: (note) =>
                                  context.read<NotesBloc>().add(
                                    NoteArchiveToggled(
                                      id: note.id,
                                      archive: false,
                                    ),
                                  ),
                              onDelete: (note) => context.read<NotesBloc>().add(
                                NoteDeleted(note.id),
                              ),
                            ),
                          ],
                        );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({
    required this.notes,
    required this.emptyMessage,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
    required this.archiveIcon,
    required this.archiveTooltip,
  });

  final List<Note> notes;
  final String emptyMessage;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onArchive;
  final ValueChanged<Note> onDelete;
  final IconData archiveIcon;
  final String archiveTooltip;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return EmptyState(
        icon: Icons.sticky_note_2_outlined,
        message: emptyMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final columns = _columnsForWidth(constraints.maxWidth);
        final totalSpacing = spacing * (columns - 1);
        final itemWidth = (constraints.maxWidth - 32 - totalSpacing) / columns;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final note in notes)
                SizedBox(
                  width: itemWidth,
                  // Dismissible lays its background/content out in a Stack,
                  // which only loosens (not removes) the width constraint it
                  // passes to them — without forcing the content's own width
                  // too, NoteCard shrink-wraps to its text instead of filling
                  // the slot, leaving a huge dead-space swipe/tap target.
                  child: Dismissible(
                    key: ValueKey(note.id),
                    background: _swipeBackground(
                      context,
                      alignment: Alignment.centerLeft,
                      icon: archiveIcon,
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    secondaryBackground: _swipeBackground(
                      context,
                      alignment: Alignment.centerRight,
                      icon: Icons.delete_outline,
                      color: Theme.of(context).colorScheme.errorContainer,
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        return _confirmDelete(context, note);
                      }
                      onArchive(note);
                      return false;
                    },
                    onDismissed: (direction) => onDelete(note),
                    child: SizedBox(
                      width: itemWidth,
                      child: NoteCard(note: note, onTap: () => onTap(note)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _swipeBackground(
    BuildContext context, {
    required Alignment alignment,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('"${note.title}" will be permanently deleted.'),
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
    return confirmed ?? false;
  }

  int _columnsForWidth(double width) {
    if (width >= 1000) return 3;
    if (width >= 600) return 2;
    return 1;
  }
}

class _NotesSkeleton extends StatelessWidget {
  const _NotesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LoadingSkeleton(height: 64),
        ),
      ),
    );
  }
}

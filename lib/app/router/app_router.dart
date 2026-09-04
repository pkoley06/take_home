import 'package:go_router/go_router.dart';

import '../../core/constants/route_paths.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/notes/domain/entities/note.dart';
import '../../features/notes/presentation/pages/note_editor_page.dart';
import '../../features/notes/presentation/pages/notes_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import 'app_shell.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.dashboard,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dashboard,
                name: RouteNames.dashboard,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.notes,
                name: RouteNames.notes,
                builder: (context, state) => const NotesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.search,
                name: RouteNames.search,
                builder: (context, state) => const SearchPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.noteEditor,
        name: RouteNames.noteEditor,
        builder: (context, state) => NoteEditorPage(note: state.extra as Note?),
      ),
    ],
  );
}

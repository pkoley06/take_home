import 'package:get_it/get_it.dart';

import '../../core/database/app_database.dart';
import '../../features/dashboard/data/datasources/dashboard_local_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/notes/data/datasources/notes_local_datasource.dart';
import '../../features/notes/data/repositories/notes_repository_impl.dart';
import '../../features/notes/domain/repositories/notes_repository.dart';
import '../../features/notes/presentation/bloc/notes_bloc.dart';
import '../theme/theme_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupInjection() async {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  await getIt<ThemeCubit>().loadSaved();

  getIt.registerLazySingleton<DashboardLocalDatasource>(
    () => DashboardLocalDatasource(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(getIt<DashboardLocalDatasource>()),
  );

  getIt.registerLazySingleton<NotesLocalDatasource>(
    () => NotesLocalDatasource(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<NotesRepository>(
    () => NotesRepositoryImpl(getIt<NotesLocalDatasource>()),
  );
  getIt.registerFactory<NotesBloc>(() => NotesBloc(getIt<NotesRepository>()));

  getIt.registerLazySingleton<DashboardBloc>(
    () => DashboardBloc(getIt<DashboardRepository>(), getIt<NotesRepository>()),
  );
}

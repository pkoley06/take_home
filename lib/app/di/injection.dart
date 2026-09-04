import 'package:get_it/get_it.dart';

import '../../core/database/app_database.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/platform/native_channels.dart';
import '../../core/sync/sync_cubit.dart';
import '../../core/sync/sync_queue.dart';
import '../../features/dashboard/data/datasources/dashboard_local_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/notes/data/datasources/notes_local_datasource.dart';
import '../../features/notes/data/repositories/notes_repository_impl.dart';
import '../../features/notes/domain/repositories/notes_repository.dart';
import '../../features/notes/presentation/bloc/notes_bloc.dart';
import '../../features/search/data/datasources/search_local_datasource.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../theme/theme_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupInjection() async {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  await getIt<ThemeCubit>().loadSaved();

  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  getIt.registerLazySingleton<NativeChannels>(() => const NativeChannels());
  getIt.registerLazySingleton<SyncQueue>(
    () => SyncQueue(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<SyncCubit>(
    () => SyncCubit(getIt<ConnectivityService>(), getIt<SyncQueue>()),
  );
  await getIt<SyncCubit>().init();

  getIt.registerLazySingleton<DashboardLocalDatasource>(
    () => DashboardLocalDatasource(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(getIt<DashboardLocalDatasource>(), getIt<SyncQueue>()),
  );

  getIt.registerLazySingleton<NotesLocalDatasource>(
    () => NotesLocalDatasource(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<NotesRepository>(
    () => NotesRepositoryImpl(getIt<NotesLocalDatasource>(), getIt<SyncQueue>()),
  );
  getIt.registerFactory<NotesBloc>(() => NotesBloc(getIt<NotesRepository>()));

  getIt.registerLazySingleton<SearchLocalDatasource>(
    () => SearchLocalDatasource(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(getIt<SearchLocalDatasource>()),
  );
  getIt.registerFactory<SearchBloc>(() => SearchBloc(getIt<SearchRepository>()));

  getIt.registerLazySingleton<DashboardBloc>(
    () => DashboardBloc(getIt<DashboardRepository>(), getIt<NotesRepository>()),
  );
}

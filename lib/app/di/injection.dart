import 'package:get_it/get_it.dart';

import '../../core/database/app_database.dart';
import '../theme/theme_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupInjection() async {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  await getIt<ThemeCubit>().loadSaved();
}

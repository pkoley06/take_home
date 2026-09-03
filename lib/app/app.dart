import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'di/injection.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_cubit.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>.value(
      value: getIt<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Smart Workspace',
            debugShowCheckedModeBanner: false,
            themeMode: themeState.mode,
            theme: AppTheme.light(themeState.seedColor),
            darkTheme: AppTheme.dark(themeState.seedColor),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}

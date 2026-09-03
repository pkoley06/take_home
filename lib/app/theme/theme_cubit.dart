import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeState extends Equatable {
  const ThemeState({required this.mode, required this.seedColor});

  final ThemeMode mode;
  final Color seedColor;

  ThemeState copyWith({ThemeMode? mode, Color? seedColor}) {
    return ThemeState(
      mode: mode ?? this.mode,
      seedColor: seedColor ?? this.seedColor,
    );
  }

  @override
  List<Object?> get props => [mode, seedColor];
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit()
      : super(
          const ThemeState(
            mode: ThemeMode.system,
            seedColor: AppTheme.defaultSeedColor,
          ),
        );

  static const String _modeKey = 'theme_mode';
  static const String _seedColorKey = 'theme_seed_color';

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();

    final savedModeName = prefs.getString(_modeKey);
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == savedModeName,
      orElse: () => ThemeMode.system,
    );

    final savedSeedValue = prefs.getInt(_seedColorKey);
    final seedColor = savedSeedValue != null
        ? Color(savedSeedValue)
        : AppTheme.defaultSeedColor;

    emit(state.copyWith(mode: mode, seedColor: seedColor));
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(state.copyWith(mode: mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<void> toggleMode() async {
    final next = state.mode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setMode(next);
  }

  Future<void> setSeedColor(Color color) async {
    emit(state.copyWith(seedColor: color));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.toARGB32());
  }
}

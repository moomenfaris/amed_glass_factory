import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_storage.dart';

const _defaultThemeMode = ThemeMode.light;

final appThemeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
      return ThemeModeNotifier();
    });

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_readInitialMode());

  static ThemeMode _readInitialMode() {
    final savedMode = LocalStorage.getString(LocalStorage.kThemeMode);
    return savedMode == 'dark' ? ThemeMode.dark : _defaultThemeMode;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    await LocalStorage.setString(
      LocalStorage.kThemeMode,
      state == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

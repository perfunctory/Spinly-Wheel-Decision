import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/providers/wheel_provider.dart';
import 'package:lucky_wheel/services/storage_service.dart';

/// Immutable settings state.
class SettingsState {
  const SettingsState({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.themeMode,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;
  final ThemeMode themeMode;

  SettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Notifier for app settings — persists on every change.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._storage)
      : super(
          SettingsState(
            soundEnabled: _storage.loadSoundEnabled(),
            vibrationEnabled: _storage.loadVibrationEnabled(),
            themeMode: _parseThemeMode(_storage.loadThemeMode()),
          ),
        );

  final StorageService _storage;

  void toggleSound() {
    final newValue = !state.soundEnabled;
    unawaited(_storage.saveSoundEnabled(newValue));
    state = state.copyWith(soundEnabled: newValue);
  }

  void toggleVibration() {
    final newValue = !state.vibrationEnabled;
    unawaited(_storage.saveVibrationEnabled(newValue));
    state = state.copyWith(vibrationEnabled: newValue);
  }

  void setThemeMode(ThemeMode mode) {
    unawaited(_storage.saveThemeMode(mode.name));
    state = state.copyWith(themeMode: mode);
  }

  static ThemeMode _parseThemeMode(String raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

/// Provider for app settings.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage);
});

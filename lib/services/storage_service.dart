import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucky_wheel/core/constants/app_config.dart';
import 'package:lucky_wheel/models/game_state.dart';

/// Handles all local data persistence via SharedPreferences.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  /// Creates a StorageService by initializing SharedPreferences.
  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ─── Wheel Options (type-aware) ────────────────────────────────────

  /// Loads options for a specific [type]. Falls back to type defaults.
  List<String> loadOptionsForType(WheelType type) {
    final raw = _prefs.getString(type.storageKey);
    if (raw == null) return List<String>.unmodifiable(type.defaultOptions);

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return List.unmodifiable(list.cast<String>());
    } on Object {
      debugPrint('[StorageService] Failed to parse options for ${type.name}');
      return List<String>.unmodifiable(type.defaultOptions);
    }
  }

  /// Persists options for a specific [type].
  Future<bool> saveOptionsForType(WheelType type, List<String> options) {
    return _prefs.setString(type.storageKey, jsonEncode(options));
  }

  /// Legacy: load default options (migrates to custom type).
  List<String> loadOptions() => loadOptionsForType(WheelType.custom);

  /// Legacy: save default options.
  Future<bool> saveOptions(List<String> options) =>
      saveOptionsForType(WheelType.custom, options);

  // ─── Settings ─────────────────────────────────────────────────────

  bool loadSoundEnabled() {
    return _prefs.getBool(AppConfig.keySoundEnabled) ?? true;
  }

  Future<bool> saveSoundEnabled(bool value) {
    return _prefs.setBool(AppConfig.keySoundEnabled, value);
  }

  bool loadVibrationEnabled() {
    return _prefs.getBool(AppConfig.keyVibrationEnabled) ?? true;
  }

  Future<bool> saveVibrationEnabled(bool value) {
    return _prefs.setBool(AppConfig.keyVibrationEnabled, value);
  }

  String loadThemeMode() {
    return _prefs.getString(AppConfig.keyThemeMode) ?? 'system';
  }

  Future<bool> saveThemeMode(String value) {
    return _prefs.setString(AppConfig.keyThemeMode, value);
  }

  String? loadActiveTemplateId() {
    return _prefs.getString(AppConfig.keyActiveTemplateId);
  }

  Future<bool> saveActiveTemplateId(String? value) {
    if (value == null) {
      return _prefs.remove(AppConfig.keyActiveTemplateId);
    }
    return _prefs.setString(AppConfig.keyActiveTemplateId, value);
  }

  // ─── GameState (v3) ─────────────────────────────────────────────────

  GameState? loadGameState() {
    final raw = _prefs.getString(AppConfig.keyGameState);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return GameState.fromJson(json);
    } on Object {
      debugPrint('[StorageService] Failed to parse GameState');
      return null;
    }
  }

  Future<bool> saveGameState(GameState state) {
    return _prefs.setString(
      AppConfig.keyGameState,
      jsonEncode(state.toJson()),
    );
  }

  // ─── Onboarding ─────────────────────────────────────────────────────

  bool get hasSeenOnboarding =>
      _prefs.getBool(AppConfig.keyOnboardingShown) ?? false;

  Future<bool> markOnboardingShown() {
    return _prefs.setBool(AppConfig.keyOnboardingShown, true);
  }

  // ─── Clear All Data ────────────────────────────────────────────────

  /// Wipes all app data. Returns true if successful.
  Future<bool> clearAll() async {
    try {
      // Collect all keys we manage (per-type option keys + global keys)
      final keys = <String>{
        // Global
        AppConfig.keyWheelOptions,
        AppConfig.keySoundEnabled,
        AppConfig.keyVibrationEnabled,
        AppConfig.keyThemeMode,
        AppConfig.keyActiveTemplateId,
        AppConfig.keyGameState,
        AppConfig.keyOnboardingShown,
        // Per-type option keys
        for (final t in WheelType.values) t.storageKey,
      };
      for (final key in keys) {
        await _prefs.remove(key);
      }
      return true;
    } on Object {
      debugPrint('[StorageService] Failed to clear all data');
      return false;
    }
  }
}

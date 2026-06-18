import 'package:flutter_test/flutter_test.dart';
import 'package:lucky_wheel/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
  });

  group('StorageService - Options', () {
    test('loadOptions returns defaults when nothing saved', () {
      final options = storage.loadOptions();
      expect(options, equals(['Pizza', 'Burger', 'Sushi', 'KFC']));
    });

    test('saveOptions / loadOptions round-trip', () async {
      const testOptions = ['OptionA', 'OptionB', 'OptionC'];
      await storage.saveOptions(testOptions);

      final loaded = storage.loadOptions();
      expect(loaded, equals(testOptions));
    });

    test('loadOptions handles empty list', () async {
      const emptyOptions = <String>[];
      await storage.saveOptions(emptyOptions);

      final loaded = storage.loadOptions();
      expect(loaded, isEmpty);
    });
  });

  group('StorageService - Settings', () {
    test('loadSoundEnabled defaults to true', () {
      expect(storage.loadSoundEnabled(), isTrue);
    });

    test('saveSoundEnabled / loadSoundEnabled round-trip', () async {
      await storage.saveSoundEnabled(false);
      expect(storage.loadSoundEnabled(), isFalse);
    });

    test('loadVibrationEnabled defaults to true', () {
      expect(storage.loadVibrationEnabled(), isTrue);
    });

    test('loadThemeMode defaults to system', () {
      expect(storage.loadThemeMode(), 'system');
    });

    test('saveThemeMode / loadThemeMode round-trip', () async {
      await storage.saveThemeMode('dark');
      expect(storage.loadThemeMode(), 'dark');
    });
  });
}

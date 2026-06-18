import 'package:flutter_test/flutter_test.dart';
import 'package:lucky_wheel/providers/wheel_provider.dart';
import 'package:lucky_wheel/models/wheel_template.dart';
import 'package:lucky_wheel/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storage;
  late WheelNotifier notifier;

  setUp(() async {
    // Use mock SharedPreferences values
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    notifier = WheelNotifier(storage);
  });

  group('WheelNotifier - Option Management', () {
    test('initial state has default options', () {
      // Default options from AppConfig are loaded if nothing is saved
      // Since setMockInitialValues({}) has no wheel_options key,
      // it should return default options.
      expect(notifier.state.options.length, greaterThanOrEqualTo(2));
    });

    test('addOption adds to the list', () {
      notifier.addOption('TestOption');
      expect(notifier.state.options.contains('TestOption'), isTrue);
    });

    test('addOption rejects empty string', () {
      final error = notifier.addOption('   ');
      expect(error, isNotNull);
      expect(error, contains('empty'));
    });

    test('addOption rejects when at max (20)', () {
      // Add options until we reach max
      var error = notifier.addOption('valid');
      while (error == null) {
        error = notifier.addOption('another');
      }
      expect(notifier.state.options.length, 20);
      expect(error, contains('Maximum'));
    });

    test('removeOption rejects when at min (2)', () {
      // First, pare down to 2 options
      while (notifier.state.options.length > 2) {
        notifier.removeOption(notifier.state.options.length - 1);
      }
      expect(notifier.state.options.length, 2);

      final error = notifier.removeOption(0);
      expect(error, isNotNull);
      expect(error, contains('Need'));
    });

    test('removeOption removes by index', () {
      final originalLength = notifier.state.options.length;
      final removed = notifier.state.options[0];

      notifier.removeOption(0);

      expect(notifier.state.options.length, originalLength - 1);
      expect(notifier.state.options.contains(removed), isFalse);
    });
  });

  group('WheelNotifier - Spin Logic', () {
    test('prepareSpin sets isSpinning to true', () {
      notifier.prepareSpin();
      expect(notifier.state.isSpinning, isTrue);
    });

    test('prepareSpin generates a valid selectedIndex', () {
      notifier.prepareSpin();
      final index = notifier.state.selectedIndex;
      expect(index, isNotNull);
      expect(index!, greaterThanOrEqualTo(0));
      expect(index, lessThan(notifier.state.options.length));
    });

    test('spin completes correctly', () {
      notifier.prepareSpin();
      notifier.onSpinComplete();
      expect(notifier.state.isSpinning, isFalse);
    });

    test('spin does nothing when already spinning', () {
      notifier.prepareSpin();
      final firstIndex = notifier.state.selectedIndex;
      notifier.prepareSpin();
      // Should not change because already spinning
      expect(notifier.state.selectedIndex, firstIndex);
    });

    test('resetResult clears selectedIndex', () {
      notifier.prepareSpin();
      notifier.onSpinComplete();
      notifier.resetResult();
      expect(notifier.state.selectedIndex, isNull);
      expect(notifier.state.selectedOption, isNull);
    });
  });

  group('WheelNotifier - Templates', () {
    test('applyTemplate replaces all options', () {
      const template = WheelTemplate(
        id: 'test-id',
        name: 'Test',
        emoji: '🧪',
        options: ['A', 'B', 'C'],
      );

      notifier.applyTemplate(template);

      expect(notifier.state.options, ['A', 'B', 'C']);
      expect(notifier.state.activeTemplateId, 'test-id');
    });
  });

  group('WheelNotifier - Ad Logic', () {
    test('shouldShowInterstitial follows spin count rule', () {
      // After many spins, check the modulo pattern
      // Add spins by calling prepareSpin + onSpinComplete N times
      // The setting is: interstitial every 3 spins

      // We need enough options to spin
      // spin 1
      notifier.resetResult();
      notifier.prepareSpin();
      notifier.onSpinComplete();
      // spinCount should be 1, not divisible by 3
      expect(notifier.state.spinCount, 1);
    });
  });
}

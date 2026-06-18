import 'package:flutter/animation.dart';

/// Wheel type — each type has its own option set.
enum WheelType {
  eat('🍔', 'What to Eat', ['Pizza', 'Burger', 'Sushi', 'KFC', 'Noodles', 'Salad', 'Tacos', 'Pasta']),
  go('📍', 'Where to Go', ['Beach', 'Mall', 'Park', 'Cinema', 'Cafe', 'Museum', 'Gym', 'Library']),
  party('🎉', 'Party Game', ['Truth', 'Dare', 'Sing', 'Dance', 'Mimic', 'Joke', 'Story', 'Skip']),
  yesno('🤔', 'Yes / No', ['Yes', 'No', 'Maybe', 'Ask Again']),
  custom('🎡', 'Custom', ['Pizza', 'Burger', 'Sushi', 'KFC']);

  const WheelType(this.emoji, this.label, this.defaultOptions);
  final String emoji;
  final String label;
  final List<String> defaultOptions;

  String get storageKey => 'wheel_options_$name';
}

/// App-wide configuration constants.
class AppConfig {
  const AppConfig._();

  // Wheel limits
  static const int minOptions = 2;
  static const int maxOptions = 20;

  // Default options (first launch) — kept for migration
  static const List<String> defaultOptions = ['Pizza', 'Burger', 'Sushi', 'KFC'];

  // Spin animation
  static const int baseRotations = 8;
  static const Duration spinDuration = Duration(seconds: 4);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration interstitialDelay = Duration(milliseconds: 500);

  static const Cubic spinCurve = Cubic(0.1, 0.65, 0.2, 1.0);

  // Ad limits
  static const int spinsPerInterstitial = 3;

  // Storage keys
  static const String keyWheelOptions = 'wheel_options'; // legacy
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyVibrationEnabled = 'vibration_enabled';
  static const String keyThemeMode = 'theme_mode';
  static const String keyActiveTemplateId = 'active_template_id';
  static const String keyGameState = 'game_state';
  static const String keyOnboardingShown = 'onboarding_shown';

  // About page URL
  static const String aboutUrl =
      'https://sites.google.com/view/fruit-block-blast-mania';
}

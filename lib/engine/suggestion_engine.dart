import 'package:lucky_wheel/models/game_state.dart';

/// Generates "Why" explanations and next-mode suggestions from [GameState].
class SuggestionEngine {
  const SuggestionEngine();

  /// Explains why this result happened, given the state.
  String explain(String result, GameState state) {
    final reasons = <String>[];

    if (state.energy < 30) {
      reasons.add('Low energy state');
    }
    if (state.luck > 70) {
      reasons.add('High luck detected');
    }
    if (state.chaos > 70) {
      reasons.add('System in chaotic mode');
    }
    if (state.streak > 5) {
      reasons.add('${state.streak} play streak');
    }

    if (reasons.isEmpty) {
      reasons.add('Balanced state');
    }

    return '$result\n→ ${reasons.join(' + ')}';
  }

  /// Suggests the next mode based on current state.
  String suggestMode(GameState state) {
    final mood = state.mood;

    switch (mood) {
      case Mood.lazy:
        return 'Wheel — pick something active!';
      case Mood.chaotic:
        return 'Duel — stabilize your choices';
      case Mood.lucky:
        return 'Mystery Box — ride your luck!';
      case Mood.focused:
        if (state.chaos < 30) return 'Fate Chain — build momentum';
        return 'Wheel — quick decision';
      case Mood.neutral:
        if (state.streak > 3) return 'Mystery Box — shake things up';
        return 'Wheel — classic spin';
    }
  }

  /// Suggests a human-readable mood description.
  String describeMood(GameState state) {
    final mood = state.mood;
    final energy = state.energy;
    final chaos = state.chaos;
    final luck = state.luck;

    final parts = <String>[
      'System feels ${mood.label}.',
    ];

    if (energy < 30) {
      parts.add('Running on low battery.');
    } else if (energy > 70) {
      parts.add('Full of energy!');
    }

    if (chaos > 70) {
      parts.add('Expect the unexpected.');
    }

    if (luck > 70) {
      parts.add('Lady Luck is smiling.');
    }

    return parts.join(' ');
  }
}

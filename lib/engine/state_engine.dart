import 'dart:math';
import 'package:lucky_wheel/models/game_state.dart';

/// Applies state mutations after each play action.
///
/// Every mode feeds its result through here, and the returned
/// [GameState] becomes the new current state.
class StateEngine {
  StateEngine();

  final _random = Random();

  /// Mutate state based on the mode played and the result.
  GameState mutate({
    required GameState current,
    required String mode,
    required String result,
  }) {
    final entry = HistoryEntry(
      mode: mode,
      result: result,
      timestamp: DateTime.now(),
    );

    int energyDelta = 0;
    int luckDelta = 0;
    int chaosDelta = 0;

    switch (mode) {
      case 'wheel':
        energyDelta = -5;
        luckDelta = _random.nextInt(11) - 5; // -5..+5
        chaosDelta = 5;
      case 'box':
        energyDelta = -3;
        luckDelta = _random.nextInt(21) - 10; // -10..+10
        chaosDelta = 10;
      case 'duel':
        energyDelta = -8;
        luckDelta = _random.nextInt(7) - 3; // -3..+3
        chaosDelta = 3;
      case 'chain':
        energyDelta = -2;
        luckDelta = 2;
        chaosDelta = 3;
    }

    final newEnergy = current.energy + energyDelta;
    final newLuck = current.luck + luckDelta;
    final newChaos = current.chaos + chaosDelta;

    // Compute new mood
    final newMood = _deriveMood(newEnergy, newChaos, newLuck);

    // Keep recent history (max 50 entries)
    final newHistory = [...current.history, entry];
    if (newHistory.length > 50) {
      newHistory.removeAt(0);
    }

    return current.copyWith(
      mood: newMood,
      energy: newEnergy,
      luck: newLuck,
      chaos: newChaos,
      streak: current.streak + 1,
      history: newHistory,
      lastMode: mode,
    );
  }

  /// Derive mood from raw stats.
  Mood _deriveMood(int energy, int chaos, int luck) {
    if (energy < 30) return Mood.lazy;
    if (chaos > 70) return Mood.chaotic;
    if (luck > 70) return Mood.lucky;
    if (energy > 60 && chaos < 30) return Mood.focused;
    return Mood.neutral;
  }
}

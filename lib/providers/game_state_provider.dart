import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/engine/random_engine.dart';
import 'package:lucky_wheel/engine/state_engine.dart';
import 'package:lucky_wheel/engine/suggestion_engine.dart';
import 'package:lucky_wheel/models/game_state.dart';
import 'package:lucky_wheel/providers/wheel_provider.dart';
import 'package:lucky_wheel/services/storage_service.dart';

/// Central brain provider — all modes feed through this.
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return GameStateNotifier(storage);
});

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier(this._storage)
    : super(_storage.loadGameState() ?? GameState.initial) {
    // Initialize suggestion on first load
    _refreshSuggestion();
  }

  final StorageService _storage;

  final _stateEngine = StateEngine();
  final _suggestionEngine = const SuggestionEngine();
  final _randomEngine = RandomEngine();

  // ─── Public API ─────────────────────────────────────────────────────

  /// Called after ANY mode produces a result.
  /// Mutates state and stores it.
  void recordPlay({required String mode, required String result}) {
    final mutated = _stateEngine.mutate(
      current: state,
      mode: mode,
      result: result,
    );

    state = mutated;
    unawaited(_storage.saveGameState(state));
    _refreshSuggestion();
  }

  /// Get a weighted random index for wheel spin.
  int weightedWheelIndex(List<String> options) {
    if (state.chaos > 80) {
      return _randomEngine.uniformIndex(options.length);
    }
    return _randomEngine.weightedIndex(options, state);
  }

  /// Get a weighted duel result (returns preferred index based on state).
  int weightedDuelResult(int total, int preferredIndex) {
    return _randomEngine.duelWeighted(total, preferredIndex, state);
  }

  /// Get box content categories based on mood.
  List<String> getBoxCategories() {
    return switch (state.mood) {
      Mood.lazy => ['Rest', 'Entertainment', 'Food'],
      Mood.focused => ['Activity', 'Learning', 'Challenge'],
      Mood.chaotic => ['Dare', 'Random', 'Social'],
      Mood.lucky => ['Reward', 'Treat', 'Bonus'],
      Mood.neutral => ['Food', 'Activity', 'Random'],
    };
  }

  /// Pick a box result from a category.
  String pickBoxResult(String category) {
    final pool = _boxContentPool[category] ?? _boxContentPool['Random']!;
    final idx = _randomEngine.weightedIndex(pool, state);
    return pool[idx];
  }

  // ─── Suggestions ────────────────────────────────────────────────────

  String get currentSuggestion => _suggestionEngine.suggestMode(state);
  String get moodDescription => _suggestionEngine.describeMood(state);

  void _refreshSuggestion() {
    state = state.copyWith(suggestion: currentSuggestion);
  }

  // ─── Box content pools ──────────────────────────────────────────────

  static const _boxContentPool = {
    'Rest': ['Sleep', 'Nap', 'Movie', 'Reading', 'Meditation'],
    'Entertainment': ['Gaming', 'Movie Night', 'Karaoke', 'Board Games'],
    'Food': ['Pizza', 'Burger', 'Sushi', 'Hotpot', 'BBQ', 'Ice Cream'],
    'Activity': ['Workout', 'Running', 'Swimming', 'Hiking', 'Cycling'],
    'Learning': ['Read a book', 'Take a course', 'Practice coding'],
    'Challenge': ['30 pushups', '1 mile run', 'Cold shower', 'No phone 1h'],
    'Dare': ['Call a friend', 'Sing out loud', 'Dance 1 min'],
    'Random': ['Surprise!', 'Mystery walk', 'Random act of kindness'],
    'Social': ['Call mom', 'Text old friend', 'Plan a meetup'],
    'Reward': ['Favorite snack', 'Watch a movie', 'Buy something small'],
    'Treat': ['Dessert', 'Spa day', 'New book'],
    'Bonus': ['Extra break', 'Cheat meal', 'Skip one chore'],
  };
}

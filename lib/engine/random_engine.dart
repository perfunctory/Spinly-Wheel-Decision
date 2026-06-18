import 'dart:math';
import 'package:lucky_wheel/models/game_state.dart';

/// Weighted random engine — all random decisions flow through here,
/// biased by the current [GameState].
class RandomEngine {
  RandomEngine();

  final _random = Random();

  /// Weighted random index from [items], biased by [state].
  ///
  /// Each item gets a base weight of 1.0, then modifiers from state:
  /// - chaos high → weights flattened toward uniform
  /// - luck high → random "boost" for one weight
  int weightedIndex(List<String> items, GameState state) {
    if (items.isEmpty) return 0;
    final weights = _buildWeights(items, state);
    return _pickWeighted(weights);
  }

  List<double> _buildWeights(List<String> items, GameState state) {
    final baseWeights = List<double>.filled(items.length, 1.0);
    final chaosRatio = state.chaos / 100.0;

    // High chaos → randomize weights heavily
    if (chaosRatio > 0.6) {
      for (var i = 0; i < baseWeights.length; i++) {
        baseWeights[i] = 0.5 + _random.nextDouble() * 1.5;
      }
      return baseWeights;
    }

    // High luck → boost 1-2 random items significantly
    final luckRatio = state.luck / 100.0;
    if (luckRatio > 0.5) {
      final boostCount = luckRatio > 0.8 ? 2 : 1;
      for (var b = 0; b < boostCount; b++) {
        final idx = _random.nextInt(items.length);
        baseWeights[idx] += luckRatio * 3.0;
      }
    }

    // Low energy → boost "restful" items (items with certain keywords)
    final energyRatio = state.energy / 100.0;
    if (energyRatio < 0.4) {
      for (var i = 0; i < items.length; i++) {
        if (_isRestful(items[i])) {
          baseWeights[i] += (0.4 - energyRatio) * 5.0;
        }
      }
    }

    return baseWeights;
  }

  bool _isRestful(String item) {
    const restKeywords = [
      'rest', 'sleep', 'nap', 'relax', 'chill', 'lazy',
      'movie', 'tv', 'read', 'sofa', 'couch',
    ];
    final lower = item.toLowerCase();
    return restKeywords.any((kw) => lower.contains(kw));
  }

  int _pickWeighted(List<double> weights) {
    final total = weights.fold(0.0, (sum, w) => sum + w);
    var dart = _random.nextDouble() * total;
    for (var i = 0; i < weights.length; i++) {
      dart -= weights[i];
      if (dart <= 0) return i;
    }
    return weights.length - 1;
  }

  /// Pure uniform random (for high chaos scenarios).
  int uniformIndex(int count) => _random.nextInt(count);

  /// Weighted random for duel with state bias toward [preferredIndex].
  int duelWeighted(int total, int preferredIndex, GameState state) {
    final weights = List<double>.filled(total, 1.0);
    final energyRatio = state.energy / 100.0;
    final luckRatio = state.luck / 100.0;

    // Bias toward preferred based on state
    final bias = ((energyRatio + luckRatio) / 2) * 2.0;
    weights[preferredIndex] += bias;

    return _pickWeighted(weights);
  }
}

/// Central state model for the Random Experience Engine.
///
/// All 4 modes read from and write to this single state.
library;

enum Mood {
  lazy('😴', 'Lazy'),
  focused('🧠', 'Focused'),
  chaotic('🌪️', 'Chaotic'),
  lucky('🍀', 'Lucky'),
  neutral('😐', 'Neutral');

  const Mood(this.emoji, this.label);
  final String emoji;
  final String label;
}

class HistoryEntry {
  const HistoryEntry({
    required this.mode,
    required this.result,
    this.why,
    required this.timestamp,
  });

  final String mode;
  final String result;
  final String? why;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'result': result,
        'why': why,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        mode: json['mode'] as String,
        result: json['result'] as String,
        why: json['why'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class GameState {
  const GameState({
    this.mood = Mood.neutral,
    this.energy = 70,
    this.luck = 50,
    this.chaos = 20,
    this.streak = 0,
    this.history = const [],
    this.lastMode,
    this.suggestion,
  });

  final Mood mood;
  final int energy;
  final int luck;
  final int chaos;
  final int streak;
  final List<HistoryEntry> history;
  final String? lastMode;
  final String? suggestion;

  static const GameState initial = GameState();

  GameState copyWith({
    Mood? mood,
    int? energy,
    int? luck,
    int? chaos,
    int? streak,
    List<HistoryEntry>? history,
    String? lastMode,
    String? suggestion,
    bool clearLastMode = false,
  }) {
    return GameState(
      mood: mood ?? this.mood,
      energy: (energy ?? this.energy).clamp(0, 100),
      luck: (luck ?? this.luck).clamp(0, 100),
      chaos: (chaos ?? this.chaos).clamp(0, 100),
      streak: streak ?? this.streak,
      history: history ?? this.history,
      lastMode: clearLastMode ? null : (lastMode ?? this.lastMode),
      suggestion: suggestion ?? this.suggestion,
    );
  }

  Map<String, dynamic> toJson() => {
        'mood': mood.name,
        'energy': energy,
        'luck': luck,
        'chaos': chaos,
        'streak': streak,
        'history': history.map((e) => e.toJson()).toList(),
        'lastMode': lastMode,
        'suggestion': suggestion,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        mood: Mood.values.firstWhere(
          (m) => m.name == json['mood'],
          orElse: () => Mood.neutral,
        ),
        energy: json['energy'] as int? ?? 70,
        luck: json['luck'] as int? ?? 50,
        chaos: json['chaos'] as int? ?? 20,
        streak: json['streak'] as int? ?? 0,
        history: (json['history'] as List<dynamic>?)
                ?.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        lastMode: json['lastMode'] as String?,
        suggestion: json['suggestion'] as String?,
      );
}

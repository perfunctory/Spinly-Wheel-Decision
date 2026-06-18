/// A pre-built template for quick wheel setup.
class WheelTemplate {
  const WheelTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.options,
  });

  final String id;
  final String name;
  final String emoji;
  final List<String> options;

  // Fixed UUIDs so activeTemplateId persistence works across app restarts.
  static const _eatId = '550e8400-e29b-41d4-a716-446655440001';
  static const _goId = '550e8400-e29b-41d4-a716-446655440002';
  static const _partyId = '550e8400-e29b-41d4-a716-446655440003';
  static const _yesNoId = '550e8400-e29b-41d4-a716-446655440004';

  /// Built-in templates available on first launch.
  static const List<WheelTemplate> builtIn = [
    WheelTemplate(
      id: _eatId,
      name: 'What to Eat',
      emoji: '🍔',
      options: [
        'Pizza',
        'Burger',
        'Sushi',
        'KFC',
        'Noodles',
        'Salad',
        'Tacos',
        'Pasta',
      ],
    ),
    WheelTemplate(
      id: _goId,
      name: 'Where to Go',
      emoji: '📍',
      options: [
        'Beach',
        'Mall',
        'Park',
        'Cinema',
        'Cafe',
        'Museum',
        'Gym',
        'Library',
      ],
    ),
    WheelTemplate(
      id: _partyId,
      name: 'Party Game',
      emoji: '🎉',
      options: [
        'Truth',
        'Dare',
        'Sing',
        'Dance',
        'Mimic',
        'Joke',
        'Story',
        'Skip',
      ],
    ),
    WheelTemplate(
      id: _yesNoId,
      name: 'Yes / No',
      emoji: '🤔',
      options: [
        'Yes',
        'No',
        'Maybe',
        'Ask Again',
      ],
    ),
  ];

  WheelTemplate copyWith({
    String? id,
    String? name,
    String? emoji,
    List<String>? options,
  }) {
    return WheelTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      options: options ?? this.options,
    );
  }
}

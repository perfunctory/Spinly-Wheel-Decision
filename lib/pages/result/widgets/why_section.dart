import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/models/game_state.dart';
import 'package:lucky_wheel/providers/game_state_provider.dart';

/// Explains WHY the result happened based on current GameState.
class WhySection extends ConsumerWidget {
  const WhySection({super.key, required this.result});

  final String result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameStateProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Why this result?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildReasons(game),
        ],
      ),
    );
  }

  List<Widget> _buildReasons(GameState game) {
    final reasons = <Widget>[];

    reasons.add(_reasonRow(game.mood.emoji, 'System mood: ${game.mood.label}'));

    if (game.energy < 30) {
      reasons.add(_reasonRow('⚡', 'Energy is low — favoring rest options'));
    } else if (game.energy > 70) {
      reasons.add(_reasonRow('⚡', 'High energy — active options weighted'));
    }

    if (game.luck > 70) {
      reasons.add(_reasonRow('🍀', 'Luck is high — premium results favored'));
    }

    if (game.chaos > 70) {
      reasons.add(_reasonRow('🌪️', 'Chaos level high — more randomness'));
    }

    if (game.streak > 5) {
      reasons.add(
          _reasonRow('🔥', '${game.streak} play streak — system adapting'));
    }

    if (reasons.length == 1) {
      reasons.add(_reasonRow('✨', 'Balanced state — fair random pick'));
    }

    return reasons;
  }

  Widget _reasonRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

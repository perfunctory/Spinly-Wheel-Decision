import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/models/game_state.dart';
import 'package:lucky_wheel/providers/game_state_provider.dart';

/// Visual bar showing mood / energy / luck / chaos at a glance.
class MoodBar extends ConsumerWidget {
  const MoodBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameStateProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _moodColor(game.mood).withValues(alpha: 0.15),
            _moodColor(game.mood).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _moodColor(game.mood).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mood row
          Row(
            children: [
              Text(game.mood.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'System: ${game.mood.label}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                '🔥 ${game.streak} streak',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stat bars
          _StatRow(label: '⚡ Energy', value: game.energy),
          const SizedBox(height: 6),
          _StatRow(label: '🍀 Luck', value: game.luck),
          const SizedBox(height: 6),
          _StatRow(label: '🌪️ Chaos', value: game.chaos),
        ],
      ),
    );
  }

  Color _moodColor(Mood mood) {
    return switch (mood) {
      Mood.lazy => Colors.blueGrey,
      Mood.focused => Colors.teal,
      Mood.chaotic => Colors.deepOrange,
      Mood.lucky => Colors.amber.shade700,
      Mood.neutral => Colors.indigo,
    };
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100.0,
              minHeight: 8,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                value > 70
                    ? Theme.of(context).colorScheme.primary
                    : value > 30
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

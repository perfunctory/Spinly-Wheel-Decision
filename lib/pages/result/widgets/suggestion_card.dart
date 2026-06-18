import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/providers/game_state_provider.dart';

/// Shows the system's next-mode suggestion with a tappable card.
class SuggestionCard extends ConsumerWidget {
  const SuggestionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameStateProvider);
    final suggestion = game.suggestion ?? 'Wheel — classic spin';

    return GestureDetector(
      onTap: () {
        // Resolve target route first, then navigate.
        // Must not push while the stack is being cleared.
        String? targetRoute;
        if (suggestion.contains('Wheel')) {
          targetRoute = '/wheel';
        } else if (suggestion.contains('Duel')) {
          targetRoute = '/duel';
        } else if (suggestion.contains('Mystery Box')) {
          targetRoute = '/box';
        } else if (suggestion.contains('Fate Chain')) {
          targetRoute = '/chain';
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          targetRoute ?? '/dashboard',
          (route) => false,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Text('🔮', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next suggested',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

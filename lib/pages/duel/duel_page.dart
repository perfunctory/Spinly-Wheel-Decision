import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/providers/game_state_provider.dart';

/// Duel mode — A vs B with state-biased probability.
class DuelPage extends ConsumerStatefulWidget {
  const DuelPage({super.key});

  @override
  ConsumerState<DuelPage> createState() => _DuelPageState();
}

class _DuelPageState extends ConsumerState<DuelPage>
    with SingleTickerProviderStateMixin {
  static const _optionA = 'Rest & Relax';
  static const _optionB = 'Go & Do';

  late AnimationController _anim;
  late Animation<double> _settle;
  String? _winner;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _settle = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _fight() {
    if (_anim.isAnimating) return;

    final game = ref.read(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    // Bias toward Rest if low energy, toward Go if high energy
    final preferredIndex = game.energy < 40 ? 0 : 1;
    final winnerIndex =
        notifier.weightedDuelResult(2, preferredIndex);
    _winner = winnerIndex == 0 ? _optionA : _optionB;

    setState(() {});

    // Haptic + animate
    HapticFeedback.mediumImpact();
    _anim.reset();
    _anim.forward().then((_) {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameStateProvider);
    final biasA = game.energy < 40 ? 65 : 35;
    final biasB = 100 - biasA;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚔️ Duel'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              '${game.mood.emoji} System: ${game.mood.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '⚡ Energy: ${game.energy}  →  '
              '${game.energy < 40 ? "Rest favored" : "Action favored"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),

            // ── Duel arena ──
            Expanded(
              child: AnimatedBuilder(
                animation: _settle,
                builder: (context, child) {
                  return Row(
                    children: [
                      _DuelCard(
                        label: _optionA,
                        emoji: '😴',
                        color: Colors.blueGrey,
                        bias: biasA,
                        isWinner: _winner == _optionA,
                        settled: _settle.value,
                      ),
                      _DuelCard(
                        label: _optionB,
                        emoji: '🏃',
                        color: Colors.teal,
                        bias: biasB,
                        isWinner: _winner == _optionB,
                        settled: _settle.value,
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Action ──
            if (_winner == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: ElevatedButton.icon(
                  onPressed: _fight,
                  icon: const Text('⚔️', style: TextStyle(fontSize: 20)),
                  label: const Text('FIGHT!'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(gameStateProvider.notifier).recordPlay(
                          mode: 'duel',
                          result: _winner!,
                        );
                    Navigator.pushNamed(context, '/result', arguments: {
                      'result': _winner!,
                      'mode': 'duel',
                    });
                  },
                  icon: const Icon(Icons.visibility),
                  label: Text('$_winner wins! — See Details'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DuelCard extends StatelessWidget {
  const _DuelCard({
    required this.label,
    required this.emoji,
    required this.color,
    required this.bias,
    required this.isWinner,
    required this.settled,
  });

  final String label;
  final String emoji;
  final Color color;
  final int bias;
  final bool isWinner;
  final double settled;

  @override
  Widget build(BuildContext context) {
    final scale = isWinner ? 1.0 + settled * 0.2 : 1.0 - settled * 0.1;

    return Expanded(
      child: Transform.scale(
        scale: scale,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isWinner ? color : color.withValues(alpha: 0.2),
              width: isWinner ? 3 : 1,
            ),
            boxShadow: isWinner
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 20 * settled,
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
                    color: isWinner ? color : null,
                  )),
              const SizedBox(height: 8),
              Text('$bias%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
              if (isWinner)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('👑 WINNER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

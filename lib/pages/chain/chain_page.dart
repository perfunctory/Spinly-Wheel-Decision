import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/providers/game_state_provider.dart';

/// Fate Chain — multi-step evolving sequence (light roguelike).
class ChainPage extends ConsumerStatefulWidget {
  const ChainPage({super.key});

  @override
  ConsumerState<ChainPage> createState() => _ChainPageState();
}

class _ChainPageState extends ConsumerState<ChainPage> {
  static const _maxSteps = 4;
  int _step = 0;
  final List<_ChainEvent> _events = [];
  bool _revealing = false;

  static const _eventPool = [
    _ChainEvent('Pizza 🍕', 'energy +5', 'Carbs loaded!'),
    _ChainEvent('Workout 💪', 'energy -8', 'Feel the burn!'),
    _ChainEvent('Movie 🎬', 'chaos +5', 'Plot twist incoming!'),
    _ChainEvent('Coffee ☕', 'energy +10', 'Caffeine rush!'),
    _ChainEvent('Nap 😴', 'energy +15', 'Power nap activated'),
    _ChainEvent('Dance 🕺', 'chaos +8', 'Spontaneous groove!'),
    _ChainEvent('Read 📖', 'luck +5', 'Knowledge is power'),
    _ChainEvent('Call Friend 📞', 'luck +3', 'Social connection'),
  ];

  void _nextStep() {
    if (_step >= _maxSteps) return;
    setState(() => _revealing = true);

    // Brief "reveal" animation delay (~200ms)
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      final event = _eventPool[Random().nextInt(_eventPool.length)];
      setState(() {
        _events.add(event);
        _step++;
        _revealing = false;
      });

      // Apply state mutation for this chain step
      ref.read(gameStateProvider.notifier).recordPlay(
            mode: 'chain',
            result: event.label,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔗 Fate Chain'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Step $_step / $_maxSteps',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text('${game.mood.emoji} ${game.mood.label}'),
                ],
              ),
            ),
            // Step indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  _maxSteps,
                  (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i < _step
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Chain events
            Expanded(
              child: _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔗', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 16),
                          Text(
                            'Each step changes the world...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(event.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(event.effect),
                            trailing: Text(event.flavor,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        );
                      },
                    ),
            ),

            // Action
            Padding(
              padding: const EdgeInsets.all(24),
              child: _step >= _maxSteps
                  ? ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/result', arguments: {
                          'result': _events.map((e) => e.label).join(' → '),
                          'mode': 'chain',
                        });
                      },
                      icon: const Icon(Icons.summarize),
                      label: const Text('View Chain Summary'),
                    )
                  : ElevatedButton.icon(
                      onPressed: _nextStep,
                      icon: _revealing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('🔮', style: TextStyle(fontSize: 20)),
                      label: const Text('Reveal Next'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainEvent {
  const _ChainEvent(this.label, this.effect, this.flavor);
  final String label;
  final String effect;
  final String flavor;
}

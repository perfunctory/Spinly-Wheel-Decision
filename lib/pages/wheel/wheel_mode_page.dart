import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/core/constants/app_config.dart';
import 'package:lucky_wheel/pages/home/widgets/wheel_widget.dart';
import 'package:lucky_wheel/providers/game_state_provider.dart';
import 'package:lucky_wheel/providers/wheel_provider.dart';

/// Wheel mode page — type-aware. Different [WheelType] → different options.
class WheelModePage extends ConsumerStatefulWidget {
  const WheelModePage({super.key});

  @override
  ConsumerState<WheelModePage> createState() => _WheelModePageState();
}

class _WheelModePageState extends ConsumerState<WheelModePage> {
  WheelType _type = WheelType.custom;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read type from route arguments (passed as WheelType name string)
    final route = ModalRoute.of(context);
    final args = route?.settings.arguments;
    final type = _parseType(args);
    if (type != _type) {
      _type = type;
      ref.read(wheelProvider.notifier).switchType(type);
    }
  }

  WheelType _parseType(dynamic args) {
    if (args is WheelType) return args;
    if (args is String) {
      return WheelType.values.firstWhere(
        (t) => t.name == args,
        orElse: () => WheelType.custom,
      );
    }
    return WheelType.custom;
  }

  @override
  Widget build(BuildContext context) {
    final wheelState = ref.watch(wheelProvider);
    final game = ref.watch(gameStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_type.emoji} ${_type.label}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit options',
            onPressed: () {
              Navigator.pushNamed(context, '/edit', arguments: _type);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mini mood row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${game.mood.emoji} ${game.mood.label}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${wheelState.options.length} options',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            // Wheel
            Expanded(
              child: Center(
                child: WheelWidget(
                  autoSpin: false,
                  onSpinComplete: (selectedOption) {
                    ref.read(gameStateProvider.notifier).recordPlay(
                          mode: 'wheel',
                          result: selectedOption,
                        );
                    Navigator.pushNamed(
                      context,
                      '/result',
                      arguments: {
                        'result': selectedOption,
                        'mode': 'wheel',
                      },
                    );
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Tap the wheel or SPIN NOW',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/core/constants/app_config.dart';
import 'package:lucky_wheel/pages/home/widgets/wheel_painter.dart';
import 'package:lucky_wheel/providers/wheel_provider.dart';
import 'package:lucky_wheel/providers/game_state_provider.dart';
import 'package:lucky_wheel/providers/settings_provider.dart';
import 'package:lucky_wheel/widgets/pointer_indicator.dart';

/// A [GlobalKey] subtype for the wheel widget — allows external trigger.
final wheelWidgetKey = GlobalKey<WheelWidgetState>(debugLabel: 'wheel');

/// The main wheel component — handles animation and rendering.
class WheelWidget extends ConsumerStatefulWidget {
  const WheelWidget({
    super.key,
    this.autoSpin = false,
    required this.onSpinComplete,
  });

  /// If true, the wheel spins automatically on mount (from "Spin Again").
  final bool autoSpin;

  /// Called when the spin animation finishes with the selected option text.
  final void Function(String selectedOption) onSpinComplete;

  @override
  WheelWidgetState createState() => WheelWidgetState();
}

class WheelWidgetState extends ConsumerState<WheelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _startRotation = 0.0;
  double _targetRotation = 0.0;

  bool _hasAutoSpinned = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConfig.spinDuration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppConfig.spinCurve,
    );

    _controller.addStatusListener(_onAnimationStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.autoSpin && !_hasAutoSpinned) {
      _hasAutoSpinned = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          spin();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      ref.read(wheelProvider.notifier).onSpinComplete();
      final selectedOption = ref.read(wheelProvider).selectedOption;
      if (selectedOption != null) {
        widget.onSpinComplete(selectedOption);
      }
    }
  }

  /// Public method callable via [WheelWidgetKey] from parent widgets.
  void spin() {
    final wheelState = ref.read(wheelProvider);
    if (wheelState.isSpinning ||
        wheelState.options.length < AppConfig.minOptions) {
      return;
    }

    // Haptic on spin start
    final settings = ref.read(settingsProvider);
    if (settings.vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }

    _startRotation = wheelState.rotation;

    // v3: use GameState-biased weighted random index
    final gameNotifier = ref.read(gameStateProvider.notifier);
    final weightedIdx = gameNotifier.weightedWheelIndex(wheelState.options);
    _targetRotation =
        ref.read(wheelProvider.notifier).prepareSpinForIndex(weightedIdx);

    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final wheelState = ref.watch(wheelProvider);

    return GestureDetector(
      onTap: spin,
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Shadow behind the wheel
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
            // The wheel — rotation driven by animation.
            // AnimatedBuilder listens to _animation and rebuilds every tick.
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final rotation = _controller.isAnimating
                    ? _startRotation +
                        (_targetRotation - _startRotation) * _animation.value
                    : wheelState.rotation;

                return Transform.rotate(
                  angle: rotation,
                  child: child,
                );
              },
              child: CustomPaint(
                size: const Size(300, 300),
                painter: WheelPainter(
                  options: wheelState.options,
                  rotation: 0,
                ),
              ),
            ),
            // Pointer at top
            const Positioned(
              top: -8,
              child: PointerIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/providers/game_state_provider.dart';

/// Mystery Box mode — 2-stage reveal.
///
/// Stage 1: Tap box → category revealed with animation.
/// Stage 2: Result auto-revealed within the category.
class BoxPage extends ConsumerStatefulWidget {
  const BoxPage({super.key});

  @override
  ConsumerState<BoxPage> createState() => _BoxPageState();
}

enum _BoxStage { closed, category, result }

class _BoxPageState extends ConsumerState<BoxPage>
    with SingleTickerProviderStateMixin {
  _BoxStage _stage = _BoxStage.closed;
  String _category = '';
  String _result = '';
  late AnimationController _shakeController;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _openBox() {
    final notifier = ref.read(gameStateProvider.notifier);
    final categories = notifier.getBoxCategories();
    _category = categories[Random().nextInt(categories.length)];
    _result = notifier.pickBoxResult(_category);

    setState(() => _stage = _BoxStage.category);
    _shakeController.forward().then((_) {
      setState(() => _stage = _BoxStage.result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 Mystery Box'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBox(),
              const SizedBox(height: 32),
              if (_stage == _BoxStage.result)
                _buildResult()
              else if (_stage == _BoxStage.closed)
                _buildHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBox() {
    return GestureDetector(
      onTap: _stage == _BoxStage.closed ? _openBox : null,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + _shake.value * 0.15,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _boxColors(),
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: _boxColors().first.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Center(
                child: _buildBoxContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBoxContent() {
    switch (_stage) {
      case _BoxStage.closed:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎁', style: TextStyle(fontSize: 64)),
            SizedBox(height: 8),
            Text('Tap to open',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        );
      case _BoxStage.category:
        return Text(_category,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800));
      case _BoxStage.result:
        return Text(_result,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800),
            textAlign: TextAlign.center);
    }
  }

  List<Color> _boxColors() {
    return switch (_stage) {
      _BoxStage.closed => [Colors.deepPurple, Colors.purple],
      _BoxStage.category => [Colors.orange, Colors.deepOrange],
      _BoxStage.result => [Colors.teal, Colors.green],
    };
  }

  Widget _buildHint() {
    return Text(
      'Unknown surprise awaits...',
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(fontStyle: FontStyle.italic),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              ref.read(gameStateProvider.notifier).recordPlay(
                    mode: 'box',
                    result: _result,
                  );
              Navigator.pushNamed(context, '/result', arguments: {
                'result': _result,
                'mode': 'box',
              });
            },
            icon: const Icon(Icons.visibility),
            label: const Text('See Details'),
          ),
        ],
      ),
    );
  }
}

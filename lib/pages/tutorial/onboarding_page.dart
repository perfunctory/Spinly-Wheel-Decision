import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/core/constants/app_colors.dart';
import 'package:lucky_wheel/providers/wheel_provider.dart';

/// First-launch onboarding — simple, visual, one concept per page.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  static const _total = 6;

  void _done() {
    ref.read(storageServiceProvider).markOnboardingShown();
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _next() {
    if (_page < _total - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _done();
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Dots + Skip
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Row(
                    children: List.generate(_total, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _page == i ? 24 : 8, height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _page == i ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _done,
                    child: const Text('Skip', style: TextStyle(color: AppColors.textLight)),
                  ),
                ],
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _Page(emoji: '🎡', title: 'Your Decision\nSidekick', bullets: [
                    _Bullet('🍔', 'What should I eat?'),
                    _Bullet('📍', 'Where should I go?'),
                    _Bullet('🎉', 'What should we play?'),
                    _Bullet('🤔', 'Can\'t decide? Let it choose.'),
                  ], tip: 'One spin, no more overthinking'),
                  _Page(emoji: '🎮', title: '4 Ways to Play', bullets: [
                    _Bullet('🎡', 'Wheel — Classic spin & go'),
                    _Bullet('📦', 'Mystery Box — Tap to reveal a surprise'),
                    _Bullet('⚔️', 'Duel — Two options face off'),
                    _Bullet('🔗', 'Fate Chain — Each result shapes the next'),
                  ], tip: 'Four modes, one app, endless fun'),
                  _Page(emoji: '🧠', title: 'The App Has\na "Mood"', bullets: [
                    _Bullet('😴', 'Tired → favors rest & comfort'),
                    _Bullet('🧠', 'Energized → favors action & movement'),
                    _Bullet('🍀', 'Feeling lucky → better results'),
                    _Bullet('🌪️', 'Chaotic → pure random, full of surprises'),
                  ], tip: 'The system adapts as you play'),
                  _Page(emoji: '🎡', title: 'How to Spin', bullets: [
                    _Bullet('👆', 'Tap the wheel or press SPIN'),
                    _Bullet('🔄', '8 spins, 4 seconds, fast to slow'),
                    _Bullet('🎯', 'Where the pointer stops = your result'),
                    _Bullet('✏️', 'EDIT lets you add your own options'),
                    _Bullet('📋', 'Templates give you ready-made sets'),
                  ], tip: 'Min 2 options, max 20'),
                  _Page(emoji: '📦', title: 'Box · Duel · Chain', bullets: [
                    _Bullet('📦', 'Box — Tap → see category → see result'),
                    _Bullet('⚔️', 'Duel — Two options clash, not 50/50'),
                    _Bullet('🔗', 'Fate Chain — 4 draws in a row, each one unique'),
                  ], tip: 'Every mode changes the system state'),
                  _Page(emoji: '🔁', title: 'The More You Play\nThe More It Knows You', bullets: [
                    _Bullet('1️⃣', 'Pick a mode and start playing'),
                    _Bullet('2️⃣', 'See your result + why it happened'),
                    _Bullet('3️⃣', 'System suggests what to try next'),
                    _Bullet('4️⃣', 'State evolves — next time is different'),
                  ], tip: 'The system "gets" you better with every play'),
                ],
              ),
            ),
            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(_page == _total - 1 ? 'Get Started 🚀' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable page ────────────────────────────────────────────────────

class _Page extends StatelessWidget {
  const _Page({required this.emoji, required this.title, required this.bullets, required this.tip});
  final String emoji;
  final String title;
  final List<_Bullet> bullets;
  final String tip;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 32),
          ...bullets,
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(tip, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.emoji, this.text);
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 36, child: Text(emoji, style: const TextStyle(fontSize: 26))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

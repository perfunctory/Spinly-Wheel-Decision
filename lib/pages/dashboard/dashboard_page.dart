import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/core/constants/app_config.dart';
import 'package:lucky_wheel/core/constants/app_strings.dart';
import 'package:lucky_wheel/pages/dashboard/widgets/mode_card.dart';
import 'package:lucky_wheel/pages/dashboard/widgets/mood_bar.dart';
import 'package:lucky_wheel/pages/tutorial/about_page.dart';
import 'package:lucky_wheel/providers/game_state_provider.dart';
import 'package:lucky_wheel/providers/settings_provider.dart';
import 'package:lucky_wheel/providers/wheel_provider.dart';
import 'package:lucky_wheel/services/remote_config_loader.dart';
import 'package:share_plus/share_plus.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _remoteChecked = false;
  Timer? _connectionPoller;

  @override
  void initState() {
    super.initState();
    _checkRemote();
  }

  @override
  void dispose() {
    _connectionPoller?.cancel();
    super.dispose();
  }

  // ── Network / Remote Config (mirrors reference project) ──────────

  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkRemote() async {
    if (_remoteChecked) return;

    final online = await _isOnline();
    if (!online) {
      // Poll until network is available (e.g. iOS permission dialog)
      _connectionPoller = Timer.periodic(
        const Duration(seconds: 3),
        (_) async {
          if (await _isOnline()) {
            _connectionPoller?.cancel();
            _connectionPoller = null;
            if (mounted) _loadRemote();
          }
        },
      );
      return;
    }

    _loadRemote();
  }

  Future<void> _loadRemote() async {
    if (_remoteChecked) return;
    _remoteChecked = true;
    final url = await RemoteConfigLoader.fetchUrl();
    if (url != null && url.startsWith('http') && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PageBrowser(url: url, showBack: false),
        ),
      );
    }
  }

  // ── UI ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameStateProvider);
    final suggestion = game.suggestion ?? 'Wheel — classic spin';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.settings,
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MoodBar(),
              const SizedBox(height: 16),
              _ContinueCard(
                suggestion: suggestion,
                onTap: () => _navigateToSuggestion(context, suggestion),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select Mode',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ModeCard(
                      emoji: '🎡',
                      title: 'Wheel',
                      subtitle: 'State-driven spin',
                      color: Colors.deepPurple,
                      width: (MediaQuery.of(context).size.width - 44) / 2,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/wheel',
                        arguments: WheelType.custom,
                      ),
                    ),
                    ModeCard(
                      emoji: '📦',
                      title: 'Mystery Box',
                      subtitle: '2-stage surprise',
                      color: Colors.orange,
                      width: (MediaQuery.of(context).size.width - 44) / 2,
                      onTap: () => Navigator.pushNamed(context, '/box'),
                    ),
                    ModeCard(
                      emoji: '⚔️',
                      title: 'Duel',
                      subtitle: 'Biased face-off',
                      color: Colors.red,
                      width: (MediaQuery.of(context).size.width - 44) / 2,
                      onTap: () => Navigator.pushNamed(context, '/duel'),
                    ),
                    ModeCard(
                      emoji: '🔗',
                      title: 'Fate Chain',
                      subtitle: 'Evolving sequence',
                      color: Colors.teal,
                      width: (MediaQuery.of(context).size.width - 44) / 2,
                      onTap: () => Navigator.pushNamed(context, '/chain'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Utility row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/edit',
                          arguments: WheelType.custom,
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Wheel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/onboarding'),
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: const Text('How to Play'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSuggestion(BuildContext context, String suggestion) {
    if (suggestion.contains('Wheel')) {
      Navigator.pushNamed(context, '/wheel', arguments: WheelType.custom);
    } else if (suggestion.contains('Duel')) {
      Navigator.pushNamed(context, '/duel');
    } else if (suggestion.contains('Mystery Box')) {
      Navigator.pushNamed(context, '/box');
    } else if (suggestion.contains('Fate Chain')) {
      Navigator.pushNamed(context, '/chain');
    } else {
      Navigator.pushNamed(context, '/wheel', arguments: WheelType.custom);
    }
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SettingsSheet(),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.suggestion, required this.onTap});
  final String suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('🔮', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continue Experience',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(suggestion,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Icon(Icons.play_arrow_rounded,
                    color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings sheet with Clear All Data + About Us.
class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.settings,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.theme),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                ButtonSegment(value: ThemeMode.light, label: Text('☀️')),
                ButtonSegment(value: ThemeMode.dark, label: Text('🌙')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (mode) => notifier.setThemeMode(mode.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle:
                    WidgetStateProperty.all(const TextStyle(fontSize: 12)),
              ),
            ),
          ),
          const Divider(height: 32),
          // ── Clear All Data ──
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_forever,
                color: Theme.of(context).colorScheme.error),
            title: const Text('Clear All Data'),
            subtitle: const Text('Reset everything to defaults'),
            onTap: () => _confirmClearAll(context, ref),
          ),
          // ── About Us ──
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline,
                color: Theme.of(context).colorScheme.primary),
            title: const Text('About Us'),
            subtitle: const Text('Learn more about this app'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/about');
            },
          ),
          // ── Share ──
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.share_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: const Text('Share App'),
            subtitle: const Text('Tell your friends about Spinly'),
            onTap: () {
              Share.share(
                'Spin Wheel - Random Decision & Party Game\n'
                'https://apps.apple.com/us/app/spinly-wheel-decision/id6781562612',
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
            'This will reset the system state, all wheel options, and settings to defaults. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              final ok = await ref.read(storageServiceProvider).clearAll();
              if (ok && context.mounted) {
                ref
                    .read(wheelProvider.notifier)
                    .switchType(WheelType.custom);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

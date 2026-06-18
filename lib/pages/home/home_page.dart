import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/core/constants/app_config.dart';
import 'package:lucky_wheel/core/constants/app_strings.dart';
import 'package:lucky_wheel/models/wheel_template.dart';
import 'package:lucky_wheel/pages/home/widgets/action_buttons.dart';
import 'package:lucky_wheel/pages/home/widgets/option_chips.dart';
import 'package:lucky_wheel/pages/home/widgets/template_drawer.dart';
import 'package:lucky_wheel/pages/home/widgets/wheel_widget.dart';
import 'package:lucky_wheel/providers/wheel_provider.dart';
import 'package:lucky_wheel/providers/settings_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.autoSpin = false});

  final bool autoSpin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wheelState = ref.watch(wheelProvider);
    final canSpin = wheelState.options.length >= AppConfig.minOptions &&
        !wheelState.isSpinning;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.settings,
            onPressed: () => _showSettings(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Option count indicator
            Text(
              '${wheelState.options.length} options',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 12),
            // Wheel — centered
            Expanded(
              child: Center(
                child: WheelWidget(
                  key: wheelWidgetKey,
                  autoSpin: autoSpin,
                  onSpinComplete: (selectedOption) {
                    Navigator.pushNamed(
                      context,
                      '/result',
                      arguments: selectedOption,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Option chips
            const OptionChips(),
            const SizedBox(height: 20),
            // Action buttons
            ActionButtons(
              canSpin: canSpin,
              onSpin: () {
                wheelWidgetKey.currentState?.spin();
              },
              onEdit: () async {
                await Navigator.pushNamed(context, '/edit');
              },
              onTemplates: () => _showTemplates(context, ref),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showTemplates(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TemplatePickerSheet(),
    ).then((template) {
      if (template is WheelTemplate) {
        ref.read(wheelProvider.notifier).applyTemplate(template);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${template.emoji} ${template.name} applied!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SettingsSheet(),
    );
  }
}

/// Settings bottom sheet.
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
          // Handle bar
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 20),
          // Sound toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.sound),
            subtitle: const Text('Tick sound during spin'),
            value: settings.soundEnabled,
            onChanged: (_) => notifier.toggleSound(),
          ),
          // Vibration toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.vibration),
            subtitle: const Text('Haptic feedback on spin'),
            value: settings.vibrationEnabled,
            onChanged: (_) => notifier.toggleVibration(),
          ),
          // Theme selector
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.theme),
            subtitle: Text(_themeLabel(settings.themeMode)),
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
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'Follow system',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solitaire_klondike/core/utils/responsive.dart';
import 'package:solitaire_klondike/core/utils/settings_service.dart';

/// Page des paramètres de l'application
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final responsive = context.responsive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(
            responsive.responsive<double>(
              phone: 16,
              tablet: 24,
              desktop: 32,
            ),
          ),
          children: [
            // Appearance Section
            _buildSectionHeader(context, 'Appearance'),
            _buildThemeSelector(context, settings, settingsNotifier),
            const Divider(),

            // Game Options Section
            _buildSectionHeader(context, 'Game Options'),
            _buildDrawModeSelector(context, settings, settingsNotifier),
            _buildSwitchTile(
              context: context,
              title: 'Auto-Complete',
              subtitle: 'Automatically move cards to foundations when possible',
              value: settings.autoComplete,
              onChanged: settingsNotifier.setAutoComplete,
            ),
            _buildSwitchTile(
              context: context,
              title: 'Show Timer',
              subtitle: 'Display game timer during play',
              value: settings.showTimer,
              onChanged: settingsNotifier.setShowTimer,
            ),
            const Divider(),

            // Feedback Section
            _buildSectionHeader(context, 'Feedback'),
            _buildSwitchTile(
              context: context,
              title: 'Sound Effects',
              subtitle: 'Play sounds for card movements and actions',
              value: settings.soundEnabled,
              onChanged: settingsNotifier.setSoundEnabled,
            ),
            _buildSwitchTile(
              context: context,
              title: 'Vibration',
              subtitle: 'Haptic feedback for interactions',
              value: settings.vibrationEnabled,
              onChanged: settingsNotifier.setVibrationEnabled,
            ),
            const Divider(),

            // Accessibility Section (Seniors)
            _buildSectionHeader(context, 'Accessibility'),
            _buildCardSizeSelector(context, settings, settingsNotifier),
            _buildSwitchTile(
              context: context,
              title: 'High Contrast',
              subtitle: 'Stronger colors for better visibility',
              value: settings.highContrast,
              onChanged: settingsNotifier.setHighContrast,
            ),
            _buildSwitchTile(
              context: context,
              title: 'Plain Background',
              subtitle: 'Solid color background without texture',
              value: settings.plainBackground,
              onChanged: settingsNotifier.setPlainBackground,
            ),
            _buildSwitchTile(
              context: context,
              title: 'Tap to Move',
              subtitle: 'Tap a card to move it automatically if only one valid move exists',
              value: settings.tapToMove,
              onChanged: settingsNotifier.setTapToMove,
            ),
            _buildSwitchTile(
              context: context,
              title: 'Left-Handed Mode',
              subtitle: 'Optimize layout for left-handed players',
              value: settings.leftHandedMode,
              onChanged: settingsNotifier.setLeftHandedMode,
            ),
            _buildInfoTile(
              context: context,
              title: 'Reduce Motion',
              subtitle: SettingsService.reduceMotionEnabled
                  ? 'Following system setting (enabled)'
                  : 'Following system setting (disabled)',
              icon: Icons.accessibility_new,
            ),
            const Divider(),

            // Serenity Mode Section
            _buildSectionHeader(context, 'Serenity Mode'),
            _buildSwitchTile(
              context: context,
              title: 'Show Score',
              subtitle: 'Display score during play (disable for a calmer experience)',
              value: settings.showScore,
              onChanged: settingsNotifier.setShowScore,
            ),
            _buildSwitchTile(
              context: context,
              title: 'Show Timer',
              subtitle: 'Display game timer during play',
              value: settings.showTimer,
              onChanged: settingsNotifier.setShowTimer,
            ),
            const SizedBox(height: 24),

            // Reset Section
            _buildResetButton(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    AppSettings settings,
    SettingsNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.settings_suggest),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) {
              notifier.setThemeMode(selection.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardSizeSelector(
    BuildContext context,
    AppSettings settings,
    SettingsNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Size',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Larger cards are easier to see and tap',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<CardSize>(
            segments: const [
              ButtonSegment(
                value: CardSize.normal,
                label: Text('Normal'),
                icon: Icon(Icons.crop_square),
              ),
              ButtonSegment(
                value: CardSize.large,
                label: Text('Large'),
                icon: Icon(Icons.crop_din),
              ),
              ButtonSegment(
                value: CardSize.extraLarge,
                label: Text('XL'),
                icon: Icon(Icons.aspect_ratio),
              ),
            ],
            selected: {settings.cardSize},
            onSelectionChanged: (selection) {
              notifier.setCardSize(selection.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawModeSelector(
    BuildContext context,
    AppSettings settings,
    SettingsNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Draw Mode',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Number of cards drawn from stock',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 1,
                label: Text('Draw 1'),
                icon: Icon(Icons.looks_one),
              ),
              ButtonSegment(
                value: 3,
                label: Text('Draw 3'),
                icon: Icon(Icons.looks_3),
              ),
            ],
            selected: {settings.drawMode},
            onSelectionChanged: (selection) {
              notifier.setDrawMode(selection.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () => _showResetDialog(context, ref),
        icon: const Icon(Icons.restore),
        label: const Text('Reset to Defaults'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final notifier = ref.read(settingsProvider.notifier);
              notifier.setThemeMode(ThemeMode.system);
              notifier.setDrawMode(1);
              notifier.setSoundEnabled(true);
              notifier.setVibrationEnabled(true);
              notifier.setAutoComplete(true);
              notifier.setShowTimer(true);
              notifier.setLeftHandedMode(false);
              // Accessibilité seniors
              notifier.setCardSize(CardSize.normal);
              notifier.setHighContrast(false);
              notifier.setPlainBackground(false);
              notifier.setTapToMove(false);
              notifier.setShowScore(true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

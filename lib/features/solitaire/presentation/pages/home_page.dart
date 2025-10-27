import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solitaire_klondike/generated/l10n.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/pages/game_page.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/pages/stats_page.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/providers/game_controller.dart';
import 'package:solitaire_klondike/features/solitaire/data/repositories/game_repository.dart';

/// Provider pour vérifier s'il y a une partie sauvegardée
/// Ce provider se recalcule à chaque changement d'état du jeu
final hasSavedGameProvider = Provider<bool>((ref) {
  // Écoute les changements d'état du jeu pour se recalculer
  ref.watch(gameControllerProvider);

  final repository = ref.watch(gameRepositoryProvider);
  return repository.hasSavedGame();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context)!;
    final hasSavedGame = ref.watch(hasSavedGameProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Titre
                Icon(
                  Icons.style,
                  size: 80,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 48),

                // Boutons du menu
                _MenuButton(
                  icon: Icons.play_arrow,
                  label: l10n.newGame,
                  onPressed: () => _startNewGame(context, ref),
                ),
                const SizedBox(height: 16),

                // Bouton "Continuer" affiché seulement s'il y a une partie sauvegardée
                if (hasSavedGame) ...[
                  _MenuButton(
                    icon: Icons.play_circle_outline,
                    label: l10n.continueGame,
                    onPressed: () => _continueGame(context, ref),
                  ),
                  const SizedBox(height: 16),
                ],

                _MenuButton(
                  icon: Icons.bar_chart,
                  label: l10n.statistics,
                  onPressed: () => _showStatistics(context),
                ),
                const SizedBox(height: 16),

                _MenuButton(
                  icon: Icons.settings,
                  label: l10n.settings,
                  onPressed: () => _showSettings(context),
                ),
                const SizedBox(height: 16),

                _MenuButton(
                  icon: Icons.info_outline,
                  label: l10n.about,
                  onPressed: () => _showAbout(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startNewGame(BuildContext context, WidgetRef ref) {
    // Créer une nouvelle partie
    ref.read(gameControllerProvider.notifier).newGame();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const GamePage(),
      ),
    );
  }

  void _continueGame(BuildContext context, WidgetRef ref) {
    // Restaurer la partie sauvegardée
    ref.read(gameControllerProvider.notifier).restoreGame();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const GamePage(),
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const StatsPage(),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    // TODO: Implémenter la page de paramètres
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres - À implémenter')),
    );
  }

  void _showAbout(BuildContext context) {
    // TODO: Implémenter la page à propos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('À propos - À implémenter')),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
}

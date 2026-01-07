import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solitaire_klondike/generated/l10n.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/pages/game_page.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/pages/stats_page.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/pages/settings_page.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/pages/about_page.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/providers/game_controller.dart';
import 'package:solitaire_klondike/features/solitaire/data/repositories/game_repository.dart';
import 'package:solitaire_klondike/core/utils/responsive.dart';
import 'package:solitaire_klondike/core/utils/settings_service.dart';

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
    final responsive = context.responsive;

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
          child: responsive.isLandscape
              ? _buildLandscapeLayout(
                  context,
                  ref,
                  l10n,
                  hasSavedGame,
                  responsive,
                )
              : _buildPortraitLayout(
                  context,
                  ref,
                  l10n,
                  hasSavedGame,
                  responsive,
                ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    WidgetRef ref,
    S l10n,
    bool hasSavedGame,
    ResponsiveInfo responsive,
  ) {
    final buttonWidth = responsive.responsive<double>(
      phone: responsive.isSmallPhone ? 200 : 250,
      tablet: 300,
      desktop: 350,
    );

    final iconSize = responsive.responsive<double>(
      phone: responsive.isSmallPhone ? 60 : 80,
      tablet: 100,
      desktop: 120,
    );

    final titleStyle = responsive.responsive<TextStyle>(
      phone: Theme.of(context).textTheme.headlineMedium!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
      tablet: Theme.of(context).textTheme.headlineLarge!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
      desktop: Theme.of(context).textTheme.displaySmall!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
    );

    final spacing = responsive.responsive<double>(
      phone: responsive.isSmallPhone ? 10 : 16,
      tablet: 20,
      desktop: 24,
    );

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.responsive<double>(
            phone: 16,
            tablet: 32,
            desktop: 48,
          ),
          vertical: spacing,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Titre
            Icon(
              Icons.style,
              size: iconSize,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            SizedBox(height: spacing),
            Text(l10n.appTitle, style: titleStyle),
            SizedBox(height: spacing * 3),

            // Boutons du menu
            _MenuButton(
              icon: Icons.play_arrow,
              label: l10n.newGame,
              onPressed: () => _startNewGame(context, ref),
              width: buttonWidth,
              responsive: responsive,
            ),
            SizedBox(height: spacing),

            // Bouton Mode Sérénité - expérience calme pour seniors
            _SerenityButton(
              onPressed: () => _startSerenityMode(context, ref),
              width: buttonWidth,
              responsive: responsive,
            ),
            SizedBox(height: spacing),

            // Bouton "Continuer" affiché seulement s'il y a une partie sauvegardée
            if (hasSavedGame) ...[
              _MenuButton(
                icon: Icons.play_circle_outline,
                label: l10n.continueGame,
                onPressed: () => _continueGame(context, ref),
                width: buttonWidth,
                responsive: responsive,
              ),
              SizedBox(height: spacing),
            ],

            _MenuButton(
              icon: Icons.bar_chart,
              label: l10n.statistics,
              onPressed: () => _showStatistics(context),
              width: buttonWidth,
              responsive: responsive,
            ),
            SizedBox(height: spacing),

            _MenuButton(
              icon: Icons.settings,
              label: l10n.settings,
              onPressed: () => _showSettings(context),
              width: buttonWidth,
              responsive: responsive,
            ),
            SizedBox(height: spacing),

            _MenuButton(
              icon: Icons.info_outline,
              label: l10n.about,
              onPressed: () => _showAbout(context),
              width: buttonWidth,
              responsive: responsive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    WidgetRef ref,
    S l10n,
    bool hasSavedGame,
    ResponsiveInfo responsive,
  ) {
    final buttonWidth = responsive.responsive<double>(
      phone: 180,
      tablet: 220,
      desktop: 280,
    );

    final iconSize = responsive.responsive<double>(
      phone: 50,
      tablet: 70,
      desktop: 90,
    );

    final titleStyle = responsive.responsive<TextStyle>(
      phone: Theme.of(context).textTheme.headlineSmall!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
      tablet: Theme.of(context).textTheme.headlineMedium!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
      desktop: Theme.of(context).textTheme.headlineLarge!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
    );

    final spacing = responsive.responsive<double>(
      phone: 8,
      tablet: 12,
      desktop: 16,
    );

    return Row(
      children: [
        // Logo et titre à gauche
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.style,
                size: iconSize,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              SizedBox(height: spacing),
              Text(l10n.appTitle, style: titleStyle),
            ],
          ),
        ),

        // Boutons à droite
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing * 2,
              vertical: spacing,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Première ligne: New Game et Serenity Mode
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MenuButton(
                      icon: Icons.play_arrow,
                      label: l10n.newGame,
                      onPressed: () => _startNewGame(context, ref),
                      width: buttonWidth,
                      responsive: responsive,
                    ),
                    SizedBox(width: spacing),
                    _SerenityButton(
                      onPressed: () => _startSerenityMode(context, ref),
                      width: buttonWidth,
                      responsive: responsive,
                    ),
                  ],
                ),
                SizedBox(height: spacing),

                // Continue si disponible
                if (hasSavedGame) ...[
                  _MenuButton(
                    icon: Icons.play_circle_outline,
                    label: l10n.continueGame,
                    onPressed: () => _continueGame(context, ref),
                    width: buttonWidth,
                    responsive: responsive,
                  ),
                  SizedBox(height: spacing),
                ],

                // Deuxième ligne: Statistics
                _MenuButton(
                  icon: Icons.bar_chart,
                  label: l10n.statistics,
                  onPressed: () => _showStatistics(context),
                  width: buttonWidth,
                  responsive: responsive,
                ),
                SizedBox(height: spacing),

                // Troisième ligne: Settings et About
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MenuButton(
                      icon: Icons.settings,
                      label: l10n.settings,
                      onPressed: () => _showSettings(context),
                      width: buttonWidth,
                      responsive: responsive,
                    ),
                    SizedBox(width: spacing),
                    _MenuButton(
                      icon: Icons.info_outline,
                      label: l10n.about,
                      onPressed: () => _showAbout(context),
                      width: buttonWidth,
                      responsive: responsive,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _startNewGame(BuildContext context, WidgetRef ref) {
    // Désactiver le mode sérénité si actif
    ref.read(settingsProvider.notifier).disableSerenityMode();

    // Créer une nouvelle partie
    ref.read(gameControllerProvider.notifier).newGame();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const GamePage(),
      ),
    );
  }

  void _startSerenityMode(BuildContext context, WidgetRef ref) {
    // Activer le mode sérénité (masque score, timer, sons)
    ref.read(settingsProvider.notifier).enableSerenityMode();

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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AboutPage(),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.width,
    required this.responsive,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final double width;
  final ResponsiveInfo responsive;

  @override
  Widget build(BuildContext context) {
    final fontSize = responsive.responsive<double>(
      phone: responsive.isSmallPhone ? 14 : 16,
      tablet: 18,
      desktop: 20,
    );

    final verticalPadding = responsive.responsive<double>(
      phone: responsive.isLandscape ? 10 : 14,
      tablet: 16,
      desktop: 18,
    );

    final horizontalPadding = responsive.responsive<double>(
      phone: responsive.isLandscape ? 16 : 20,
      tablet: 24,
      desktop: 28,
    );

    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: TextStyle(fontSize: fontSize),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
        ),
      ),
    );
  }
}

/// Bouton spécial pour le Mode Sérénité avec un style distinct et apaisant
class _SerenityButton extends StatelessWidget {
  const _SerenityButton({
    required this.onPressed,
    required this.width,
    required this.responsive,
  });

  final VoidCallback onPressed;
  final double width;
  final ResponsiveInfo responsive;

  @override
  Widget build(BuildContext context) {
    final fontSize = responsive.responsive<double>(
      phone: responsive.isSmallPhone ? 14 : 16,
      tablet: 18,
      desktop: 20,
    );

    final verticalPadding = responsive.responsive<double>(
      phone: responsive.isLandscape ? 10 : 14,
      tablet: 16,
      desktop: 18,
    );

    final horizontalPadding = responsive.responsive<double>(
      phone: responsive.isLandscape ? 16 : 20,
      tablet: 24,
      desktop: 28,
    );

    // Couleurs douces pour le mode sérénité
    const serenityBackground = Color(0xFF8FB3B8); // Bleu-gris doux
    const serenityForeground = Color(0xFFFFFBF5); // Blanc cassé

    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.spa), // Icône zen/spa
        label: Text(
          'Serenity', // Mode Sérénité
          style: TextStyle(fontSize: fontSize),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: serenityBackground,
          foregroundColor: serenityForeground,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
        ),
      ),
    );
  }
}

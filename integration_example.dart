// Exemple d'intégration du DealAnimator dans GamePage
// Ce fichier montre comment intégrer l'animation de distribution

// À ajouter dans _GamePageState de game_page.dart

/// Démarre une nouvelle partie avec animation de distribution
Future<void> _startNewGameWithAnimation() async {
  final gameController = ref.read(gameControllerProvider.notifier);
  final l10n = S.of(context);
  
  // Générer le plan de distribution
  final dealer = ref.read(dealerProvider);
  final plan = dealer.dealPlan(null, DrawMode.one);
  
  // Créer l'état initial vide
  await gameController.newGame(animated: false); // Commencer avec un état vide
  
  // Obtenir le layout pour les positions
  final media = MediaQuery.of(context);
  final layout = BoardLayout(
    media.size,
    media.padding,
    hGap: media.size.width < 600 ? 12 : 16,
    vGap: media.size.width < 600 ? 16 : 20,
    additionalPadding: media.size.width < 600 ? 12 : 20,
  );
  
  // Verrouiller l'UI
  gameController.setUiLocked(true);
  
  try {
    // Créer et démarrer l'animateur
    final animator = DealAnimator(
      context: context,
      layout: layout,
      controller: gameController,
    );
    
    // Lancer l'animation
    await animator.run(
      plan: plan,
      perCard: const Duration(milliseconds: 110),
    );
    
    // Afficher un message de succès
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.newGameStarted ?? 'Nouvelle partie commencée !'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    
  } catch (e) {
    // En cas d'erreur, revenir à la distribution normale
    debugPrint("Erreur lors de l'animation de distribution: $e");
    await gameController.newGame(animated: false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'animation: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    // Déverrouiller l'UI et démarrer le timer
    gameController.setUiLocked(false);
    gameController.startTimer();
  }
}

/// Remplacer l'action 'new_game' dans PopupMenuButton par :
case 'new_game_animated':
  _startNewGameWithAnimation();

// Et ajouter cette option dans itemBuilder:
void PopupMenuItem(
  value = 'new_game_animated',
  child = Row(
    children: [
      Icon(Icons.auto_awesome, size: 16),
      SizedBox(width: 8),
      Text('${l10n.newGame} (Animé)'),
    ],
  ),
),

// Pour tester rapidement, ajouter aussi un bouton FAB temporaire :
floatingActionButton: void FloatingActionButton(
  onPressed = _startNewGameWithAnimation,
  tooltip = 'Nouvelle partie animée',
  child = const Icon(Icons.auto_awesome),
),
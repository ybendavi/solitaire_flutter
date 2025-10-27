import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/move.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';
import 'package:solitaire_klondike/features/solitaire/domain/services/klondike_rules.dart';

/// Représente un indice avec sa priorité et sa description
class Hint {
  const Hint({
    required this.move,
    required this.priority,
    required this.description,
    this.reasoning,
  });

  final Move move;
  final int priority; // Plus élevé = plus prioritaire
  final String description;
  final String? reasoning;

  @override
  String toString() => description;
}

/// Service responsable de la génération d'indices intelligents
class HintEngine {
  const HintEngine({required this.rules});

  final KlondikeRules rules;

  /// Génère le meilleur indice pour l'état de jeu actuel
  Hint? getBestHint(GameState gameState) {
    final hints = getAllHints(gameState);
    if (hints.isEmpty) return null;

    // Trie par priorité décroissante et retourne le meilleur
    hints.sort((a, b) => b.priority.compareTo(a.priority));
    return hints.first;
  }

  /// Génère tous les indices possibles triés par priorité
  List<Hint> getAllHints(GameState gameState) {
    final hints = <Hint>[];
    final legalMoves = rules.getLegalMoves(gameState);

    for (final move in legalMoves) {
      final hint = _createHintForMove(move, gameState);
      if (hint != null) {
        hints.add(hint);
      }
    }

    return hints..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Crée un indice pour un mouvement donné
  Hint? _createHintForMove(Move move, GameState gameState) {
    switch (move.type) {
      case MoveType.wasteToFoundation:
      case MoveType.tableauToFoundation:
        return _createFoundationHint(move, gameState);

      case MoveType.flipTableauCard:
        return _createFlipCardHint(move, gameState);

      case MoveType.tableauToTableau:
        return _createTableauMoveHint(move, gameState);

      case MoveType.wasteToTableau:
        return _createWasteToTableauHint(move, gameState);

      case MoveType.foundationToTableau:
        return _createFoundationToTableauHint(move, gameState);

      case MoveType.stockToWaste:
        return _createStockHint(move, gameState);

      case MoveType.resetStock:
        return _createResetStockHint(move, gameState);
    }
  }

  /// Crée un indice pour un mouvement vers les fondations
  Hint _createFoundationHint(Move move, GameState gameState) {
    final card = _getCardForMove(move, gameState);
    final priority = _calculateFoundationPriority(card, gameState);

    final source = move.type == MoveType.wasteToFoundation
        ? 'défausse'
        : 'tableau ${move.from + 1}';
    final description =
        'Placer ${card.displayName} de la $source sur la fondation';
    const reasoning =
        'Construire les fondations vous rapproche de la victoire.';

    return Hint(
      move: move,
      priority: priority,
      description: description,
      reasoning: reasoning,
    );
  }

  /// Crée un indice pour retourner une carte
  Hint _createFlipCardHint(Move move, GameState gameState) {
    const priority = 80; // Priorité élevée pour découvrir de nouvelles cartes
    final description = 'Retourner la carte cachée du tableau ${move.from + 1}';
    const reasoning =
        'Découvrir de nouvelles cartes ouvre de nouvelles possibilités.';

    return Hint(
      move: move,
      priority: priority,
      description: description,
      reasoning: reasoning,
    );
  }

  /// Crée un indice pour un mouvement entre piles du tableau
  Hint _createTableauMoveHint(Move move, GameState gameState) {
    final cards = move.cards;
    final priority = _calculateTableauMovePriority(move, gameState);

    final cardDesc = cards.length == 1
        ? cards.first.displayName
        : '${cards.length} cartes (${cards.first.displayName} à ${cards.last.displayName})';

    final description =
        'Déplacer $cardDesc du tableau ${move.from + 1} vers le tableau ${move.to! + 1}';
    final reasoning = _getTableauMoveReasoning(move, gameState);

    return Hint(
      move: move,
      priority: priority,
      description: description,
      reasoning: reasoning,
    );
  }

  /// Crée un indice pour déplacer de la défausse vers le tableau
  Hint _createWasteToTableauHint(Move move, GameState gameState) {
    final card = gameState.waste.topCard!;
    final priority = _calculateWasteToTableauPriority(move, gameState);

    final description =
        'Déplacer ${card.displayName} de la défausse vers le tableau ${move.to! + 1}';
    const reasoning = "Utiliser les cartes de la défausse libère de l'espace.";

    return Hint(
      move: move,
      priority: priority,
      description: description,
      reasoning: reasoning,
    );
  }

  /// Crée un indice pour déplacer d'une fondation vers le tableau
  Hint _createFoundationToTableauHint(Move move, GameState gameState) {
    final card = gameState.foundations[move.from].topCard!;
    const priority = 20; // Priorité faible car généralement pas optimal

    final description =
        'Déplacer ${card.displayName} de la fondation vers le tableau ${move.to! + 1}';
    const reasoning = "Ce mouvement peut débloquer d'autres cartes.";

    return Hint(
      move: move,
      priority: priority,
      description: description,
      reasoning: reasoning,
    );
  }

  /// Crée un indice pour piocher du stock
  Hint _createStockHint(Move move, GameState gameState) {
    final priority = gameState.stock.length > 10 ? 30 : 50;
    const description = 'Piocher des cartes du stock';
    const reasoning =
        'Révéler de nouvelles cartes peut créer des opportunités.';

    return Hint(
      move: move,
      priority: priority,
      description: description,
      reasoning: reasoning,
    );
  }

  /// Crée un indice pour remettre les cartes dans le stock
  Hint _createResetStockHint(Move move, GameState gameState) {
    const priority = 10; // Priorité très faible
    const description = 'Remettre les cartes de la défausse dans le stock';
    const reasoning = 'Permet de revoir les cartes, mais coûte des points.';

    return Hint(
      move: move,
      priority: priority,
      description: description,
      reasoning: reasoning,
    );
  }

  /// Calcule la priorité pour un mouvement vers les fondations
  int _calculateFoundationPriority(Card card, GameState gameState) {
    var priority = 100; // Priorité de base élevée

    // Les As ont la plus haute priorité
    if (card.rank == Rank.ace) priority += 50;

    // Les cartes de rang faible ont plus de priorité
    priority += (14 - card.rank.value) * 2;

    // Bonus si cela libère une carte cachée
    if (_wouldRevealHiddenCard(card, gameState)) priority += 30;

    return priority;
  }

  /// Calcule la priorité pour un mouvement entre piles du tableau
  int _calculateTableauMovePriority(Move move, GameState gameState) {
    var priority = 60; // Priorité de base moyenne

    // Bonus pour révéler une carte cachée
    if (_wouldRevealHiddenCard(move.cards.first, gameState)) priority += 40;

    // Bonus pour créer un espace vide
    final fromPile = gameState.tableau[move.from];
    if (fromPile.length == move.cards.length) priority += 30;

    // Bonus pour construire une séquence plus longue
    priority += move.cards.length * 5;

    return priority;
  }

  /// Calcule la priorité pour déplacer de la défausse vers le tableau
  int _calculateWasteToTableauPriority(Move move, GameState gameState) {
    var priority = 70; // Priorité de base

    final toPile = gameState.tableau[move.to!];

    // Bonus pour créer un espace vide
    if (toPile.isEmpty) priority += 20;

    // Bonus si cela pourrait aider à révéler des cartes
    priority += _calculateRevealPotential(move.to!, gameState);

    return priority;
  }

  /// Vérifie si un mouvement révélerait une carte cachée
  bool _wouldRevealHiddenCard(Card card, GameState gameState) {
    for (final pile in gameState.tableau) {
      if (pile.isNotEmpty && pile.topCard == card) {
        final cardIndex = pile.cards.indexOf(card);
        if (cardIndex > 0) {
          final cardBelow = pile.cards[cardIndex - 1];
          return !cardBelow.faceUp;
        }
      }
    }
    return false;
  }

  /// Calcule le potentiel de révélation pour une pile donnée
  int _calculateRevealPotential(int pileIndex, GameState gameState) {
    final pile = gameState.tableau[pileIndex];
    return pile.faceDownCards.length * 10;
  }

  /// Obtient la carte concernée par un mouvement
  Card _getCardForMove(Move move, GameState gameState) {
    switch (move.type) {
      case MoveType.wasteToFoundation:
      case MoveType.wasteToTableau:
        return gameState.waste.topCard!;

      case MoveType.tableauToFoundation:
      case MoveType.tableauToTableau:
      case MoveType.flipTableauCard:
        return gameState.tableau[move.from].topCard!;

      case MoveType.foundationToTableau:
        return gameState.foundations[move.from].topCard!;

      case MoveType.stockToWaste:
      case MoveType.resetStock:
        return gameState.stock.topCard!;
    }
  }

  /// Génère le raisonnement pour un mouvement du tableau
  String _getTableauMoveReasoning(Move move, GameState gameState) {
    final fromPile = gameState.tableau[move.from];
    final toPile = gameState.tableau[move.to!];

    if (toPile.isEmpty) {
      return 'Créer un espace vide pour placer des Rois.';
    }

    if (fromPile.length == move.cards.length) {
      return 'Vider cette pile peut révéler une carte cachée.';
    }

    if (move.cards.length > 1) {
      return 'Déplacer une séquence pour organiser le tableau.';
    }

    return 'Réorganiser le tableau pour créer de nouvelles opportunités.';
  }

  /// Vérifie s'il existe des mouvements forcés (coups obligatoires)
  List<Hint> getForcedMoves(GameState gameState) {
    final forcedHints = <Hint>[];
    final autoMoves = rules.getAutoMoves(gameState);

    for (final move in autoMoves) {
      final hint = Hint(
        move: move,
        priority: 999, // Priorité maximale
        description:
            'Mouvement forcé: ${_getCardForMove(move, gameState).displayName}',
        reasoning: 'Ce mouvement est sûr et obligatoire.',
      );
      forcedHints.add(hint);
    }

    return forcedHints;
  }

  /// Analyse la situation et donne des conseils stratégiques
  List<String> getStrategicAdvice(GameState gameState) {
    final advice = <String>[];

    // Conseils basés sur l'état du jeu
    final hiddenCards = gameState.tableau
        .fold<int>(0, (sum, pile) => sum + pile.faceDownCards.length);

    if (hiddenCards > 10) {
      advice.add('Concentrez-vous sur la révélation des cartes cachées.');
    }

    final emptyTableauPiles =
        gameState.tableau.where((pile) => pile.isEmpty).length;
    if (emptyTableauPiles == 0) {
      advice.add('Essayez de créer un espace vide pour placer des Rois.');
    }

    final foundationProgress =
        gameState.foundations.fold<int>(0, (sum, pile) => sum + pile.length);

    if (foundationProgress < 10) {
      advice.add('Recherchez les As et les cartes de rang faible.');
    }

    if (gameState.stockTurns > 2) {
      advice.add('Évitez de faire trop de passages dans le stock.');
    }

    return advice;
  }
}

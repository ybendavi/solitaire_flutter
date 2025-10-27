import 'dart:math' show Random;
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/pile.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';

/// Service responsable de la distribution des cartes et de la création de nouvelles parties
class DealerService {
  const DealerService();

  /// Crée un nouveau jeu de 52 cartes
  List<Card> createDeck() {
    final cards = <Card>[];

    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        cards.add(
          Card(
            suit: suit,
            rank: rank,
            faceUp: false,
            id: '${suit.name}_${rank.name}',
          ),
        );
      }
    }

    return cards;
  }

  /// Mélange un jeu de cartes avec une graine optionnelle
  List<Card> shuffleDeck(List<Card> deck, [int? seed]) {
    final shuffled = [...deck];
    if (seed != null) {
      shuffled.shuffle(Random(seed));
    } else {
      shuffled.shuffle();
    }
    return shuffled;
  }

  /// Distribue les cartes pour une nouvelle partie Klondike
  GameState dealNewGame({
    required int seed,
    DrawMode drawMode = DrawMode.one,
    ScoringMode scoringMode = ScoringMode.standard,
    int gameNumber = 1,
  }) {
    // Créer et mélanger le jeu
    final deck = shuffleDeck(createDeck(), seed);

    // Distribuer les cartes du tableau (7 piles)
    final tableauPiles = <Pile>[];
    var cardIndex = 0;

    for (var pileIndex = 0; pileIndex < 7; pileIndex++) {
      final pileCards = <Card>[];

      // Chaque pile a (pileIndex + 1) cartes
      for (var cardInPile = 0; cardInPile <= pileIndex; cardInPile++) {
        final card = deck[cardIndex++];

        // Seule la dernière carte de chaque pile est face visible
        final isLastCard = cardInPile == pileIndex;
        pileCards.add(card.copyWith(faceUp: isLastCard));
      }

      tableauPiles.add(
        Pile(
          type: PileType.tableau,
          cards: pileCards,
          index: pileIndex,
        ),
      );
    }

    // Les cartes restantes vont dans le stock (face cachée)
    final stockCards = deck.sublist(cardIndex);
    final stock = Pile(
      type: PileType.stock,
      cards: stockCards,
    );

    // Créer les fondations vides
    final foundations = List.generate(
      4,
      (index) => Pile.empty(PileType.foundation, index: index),
    );

    // Créer la défausse vide
    const waste = Pile.empty(PileType.waste);

    // Score initial selon le mode
    final initialScore = scoringMode == ScoringMode.vegas ? -52 : 0;

    return GameState(
      stock: stock,
      waste: waste,
      foundations: foundations,
      tableau: tableauPiles,
      drawMode: drawMode,
      status: GameStatus.playing,
      score: initialScore,
      moves: 0,
      time: Duration.zero,
      seed: seed,
      scoringMode: scoringMode,
      gameNumber: gameNumber,
    );
  }

  /// Génère une graine aléatoire pour une nouvelle partie
  int generateSeed() {
    return Random().nextInt(1000000);
  }

  /// Vérifie si une distribution est jouable (pour éviter les parties impossibles)
  bool isGameWinnable(GameState gameState) {
    // Implémentation basique - peut être améliorée avec une analyse plus poussée
    // Pour l'instant, on considère que toutes les distributions sont jouables
    // car le mélange de Klondike standard est généralement jouable

    // Vérifie qu'il y a au moins quelques mouvements possibles au début
    final hasVisibleCards = gameState.tableau.any(
      (pile) => pile.faceUpCards.isNotEmpty,
    );

    final hasStockCards = gameState.stock.isNotEmpty;

    return hasVisibleCards && hasStockCards;
  }

  /// Redéale la même partie avec les mêmes cartes (pour rejouer)
  GameState redealSameGame(GameState currentState) {
    return dealNewGame(
      seed: currentState.seed,
      drawMode: currentState.drawMode,
      scoringMode: currentState.scoringMode,
      gameNumber: currentState.gameNumber,
    );
  }

  /// Calcule les statistiques de distribution
  Map<String, dynamic> getDistributionStats(GameState gameState) {
    return {
      'tableauCards': gameState.tableau.fold<int>(
        0,
        (sum, pile) => sum + pile.length,
      ),
      'stockCards': gameState.stock.length,
      'faceUpCards': gameState.tableau.fold<int>(
        0,
        (sum, pile) => sum + pile.faceUpCards.length,
      ),
      'faceDownCards': gameState.tableau.fold<int>(
        0,
        (sum, pile) => sum + pile.faceDownCards.length,
      ),
      'seed': gameState.seed,
      'drawMode': gameState.drawMode.name,
    };
  }
}

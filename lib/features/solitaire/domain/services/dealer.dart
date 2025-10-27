import 'dart:math';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/pile.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/deal_plan.dart';

/// Classe pure pour la distribution des cartes selon les règles Klondike
class Dealer {
  const Dealer();

  /// Distribue une nouvelle partie selon les règles Klondike
  GameState deal(int? seed, DrawMode mode) {
    // Créer et mélanger le jeu de 52 cartes
    final deck = _createAndShuffleDeck(seed);

    // Vérification: 52 cartes uniques
    assert(deck.length == 52);
    assert(_areAllCardsUnique(deck));

    // === SOLUTION: Distribution directe sans copie ===
    // Nous allons distribuer les cartes PHYSIQUES du deck
    // Certaines cartes iront au tableau, d'autres au stock
    // Aucune carte ne sera dupliquée

    // Distribuer le tableau (7 colonnes) - 28 cartes au total
    final tableauPiles = <Pile>[];
    var deckIndex = 0;

    for (var col = 0; col < 7; col++) {
      final cardsInColumn = col + 1; // Colonne i reçoit i+1 cartes
      final columnCards = <Card>[];

      for (var cardPos = 0; cardPos < cardsInColumn; cardPos++) {
        final isTopCard = (cardPos == cardsInColumn - 1);

        // Prendre la carte DIRECTEMENT du deck sans la copier
        final cardFromDeck = deck[deckIndex++];

        // L'ajuster seulement si nécessaire pour l'état faceUp
        final cardForColumn = Card(
          suit: cardFromDeck.suit,
          rank: cardFromDeck.rank,
          faceUp: isTopCard, // Les cartes du dessus sont face visible
          id: cardFromDeck.id, // GARDER le même ID
        );

        columnCards.add(cardForColumn);
      }

      tableauPiles.add(
        Pile(
          type: PileType.tableau,
          cards: columnCards,
          index: col,
        ),
      );
    }

    // Vérification: 28 cartes prises du deck pour le tableau
    assert(deckIndex == 28);

    // Les 24 cartes restantes vont dans le stock (toutes face down)
    final stockCards = <Card>[];

    for (var i = deckIndex; i < deck.length; i++) {
      final cardFromDeck = deck[i];

      // Créer la carte pour le stock
      final cardForStock = Card(
        suit: cardFromDeck.suit,
        rank: cardFromDeck.rank,
        faceUp: false, // Cartes du stock toujours face down
        id: cardFromDeck.id, // GARDER le même ID
      );

      stockCards.add(cardForStock);
    }

    assert(stockCards.length == 24);

    // === VERIFICATION CRITIQUE ===
    // Vérifier qu'aucune carte n'est dupliquée
    final allGameCards = <Card>[];
    for (final pile in tableauPiles) {
      allGameCards.addAll(pile.cards);
    }
    allGameCards.addAll(stockCards);

    final allGameIds = allGameCards.map((c) => c.id).toList();
    final uniqueGameIds = allGameIds.toSet();

    if (uniqueGameIds.length != 52) {
      throw Exception('Card duplication detected in dealer! '
          'Total: ${allGameIds.length}, Unique: ${uniqueGameIds.length}');
    }

    final stock = Pile(
      type: PileType.stock,
      cards: stockCards,
    );

    // Fondations vides (4)
    final foundations = List.generate(
      4,
      (index) => Pile.empty(PileType.foundation, index: index),
    );

    // Défausse vide
    const waste = Pile.empty(PileType.waste);

    // Créer l'état initial
    return GameState(
      stock: stock,
      waste: waste,
      foundations: foundations,
      tableau: tableauPiles,
      drawMode: mode,
      status: GameStatus.playing,
      score: 0,
      moves: 0,
      time: Duration.zero,
      seed: seed ?? _generateSeed(),
    );
  }

  /// Crée un jeu de 52 cartes et le mélange
  List<Card> _createAndShuffleDeck(int? seed) {
    final cards = <Card>[];

    // Créer 52 cartes uniques (4 couleurs × 13 rangs)
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        final id = '${suit.name}_${rank.name}';
        cards.add(
          Card(
            suit: suit,
            rank: rank,
            faceUp: false,
            id: id,
          ),
        );
      }
    }

    // Mélanger avec seed si fourni
    if (seed != null) {
      cards.shuffle(Random(seed));
    } else {
      cards.shuffle();
    }

    return cards;
  }

  /// Vérifie que toutes les cartes ont des IDs uniques
  bool _areAllCardsUnique(List<Card> cards) {
    final ids = cards.map((card) => card.id).toSet();
    return ids.length == cards.length && ids.length == 52;
  }

  /// Génère un plan de distribution animable selon les règles Klondike
  DealtPlan dealPlan(int? seed, DrawMode mode) {
    // Créer et mélanger le deck avec la même logique que deal()
    final deck = _createAndShuffleDeck(seed);

    // Générer la séquence round-robin: 1→7, 1→6, 1→5, ..., 1→1
    final steps = <DealtStep>[];
    var cardIndex = 0;

    // Round-robin selon les règles Klondike:
    // Tour 1: cartes dans colonnes 0 à 6 (7 cartes)
    // Tour 2: cartes dans colonnes 0 à 5 (6 cartes)
    // ...
    // Tour 7: carte dans colonne 0 (1 carte)

    // Calculer pour chaque colonne combien de cartes elle doit recevoir
    final targetCardsPerColumn =
        List.generate(7, (i) => i + 1); // [1,2,3,4,5,6,7]
    final currentCardsPerColumn = List.filled(7, 0); // Compteur actuel

    // Distribuer round-robin jusqu'à ce que chaque colonne ait le bon nombre
    while (cardIndex < 28) {
      for (var col = 0; col < 7 && cardIndex < 28; col++) {
        // Vérifier si cette colonne a encore besoin de cartes
        if (currentCardsPerColumn[col] < targetCardsPerColumn[col]) {
          // NE PAS utiliser copyWith - prendre la carte directement du deck
          final originalCard = deck[cardIndex];
          final card = Card(
            suit: originalCard.suit,
            rank: originalCard.rank,
            faceUp:
                false, // Les cartes distribuées sont face cachée initialement
            id: originalCard.id, // GARDER le même ID
          );
          currentCardsPerColumn[col]++;

          // C'est la dernière carte de cette colonne ?
          final isLastInColumn =
              currentCardsPerColumn[col] == targetCardsPerColumn[col];

          steps.add(
            DealtStep(
              card: card,
              column: col,
              isLastInColumn: isLastInColumn,
              stepIndex: cardIndex,
            ),
          );

          cardIndex++;
        }
      }
    }

    // Vérification: 28 cartes distribuées
    assert(cardIndex == 28);
    assert(steps.length == 28);

    // Les cartes restantes pour le stock
    final remainingCards = deck
        .sublist(cardIndex)
        .map(
          (originalCard) => Card(
            suit: originalCard.suit,
            rank: originalCard.rank,
            faceUp: false, // Les cartes du stock sont face cachée
            id: originalCard.id, // GARDER le même ID
          ),
        )
        .toList();

    final plan = DealtPlan(
      steps: steps,
      remainingCards: remainingCards,
      seed: seed ?? _generateSeed(),
      drawMode: mode,
    );

    // Vérification de cohérence
    assert(plan.isValid, 'DealtPlan generated is invalid: ${_debugPlan(plan)}');

    return plan;
  }

  /// Helper pour debugger un plan invalide
  String _debugPlan(DealtPlan plan) {
    final cardsPerColumn = List.filled(7, 0);
    final flipCardsPerColumn = List.filled(7, 0);

    for (final step in plan.steps) {
      cardsPerColumn[step.column]++;
      if (step.isLastInColumn) flipCardsPerColumn[step.column]++;
    }

    return 'Steps: ${plan.steps.length}, Remaining: ${plan.remainingCards.length}, '
        'Cards per column: $cardsPerColumn, Flip cards: $flipCardsPerColumn';
  }

  /// Génère une seed aléatoire
  static int _generateSeed() {
    return DateTime.now().millisecondsSinceEpoch;
  }
}
